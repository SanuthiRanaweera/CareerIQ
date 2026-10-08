const PersonalityTest = require('../models/PersonalityTest');
const PersonalityQuestion = require('../models/PersonalityQuestion');
const Student = require('../models/Student');
const Course = require('../models/Course');
const { recommendCareers } = require('./careerRecommendationService');
const { QUESTIONS: DEFAULT_SEED_QUESTIONS } = require('../data/personalityQuestions');
const PERSONALITY_TYPES = require('../data/personalityTypes');

const DEFAULT_LIKERT_OPTIONS = [
  { text: 'Strongly Agree', score: 5 },
  { text: 'Agree', score: 4 },
  { text: 'Neutral', score: 3 },
  { text: 'Disagree', score: 2 },
  { text: 'Strongly Disagree', score: 1 },
];

/**
 * Ensures initial questions are seeded into MongoDB if collection is empty.
 */
async function ensureDefaultQuestions() {
  const count = await PersonalityQuestion.countDocuments();
  if (count === 0 && Array.isArray(DEFAULT_SEED_QUESTIONS) && DEFAULT_SEED_QUESTIONS.length > 0) {
    const seedDocs = DEFAULT_SEED_QUESTIONS.map((q, index) => ({
      questionText: q.text,
      type: 'personality',
      category: q.category.toLowerCase(),
      answerType: 'likert',
      options: DEFAULT_LIKERT_OPTIONS,
      reverseScoring: false,
      displayOrder: index + 1,
      isActive: true,
    }));
    await PersonalityQuestion.insertMany(seedDocs);
    console.log(`[Personality] Auto-seeded ${seedDocs.length} default questions into MongoDB.`);
  }
}

/**
 * Returns active questions for students from MongoDB.
 */
async function getQuestionSet() {
  await ensureDefaultQuestions();

  const questions = await PersonalityQuestion.find({ isActive: true })
    .sort({ displayOrder: 1, createdAt: 1 })
    .lean();

  const formattedQuestions = questions.map((q) => ({
    _id: q._id.toString(),
    id: q._id.toString(),
    questionText: q.questionText,
    text: q.questionText,
    type: q.type,
    category: q.category,
    answerType: q.answerType || 'likert',
    options: (q.options && q.options.length ? q.options : DEFAULT_LIKERT_OPTIONS).map((opt) => ({
      label: opt.text,
      value: opt.score,
      text: opt.text,
      score: opt.score,
    })),
    reverseScoring: q.reverseScoring || false,
    displayOrder: q.displayOrder || 1,
  }));

  // Options preview for backward compatibility
  const options = DEFAULT_LIKERT_OPTIONS.map((opt) => ({
    label: opt.text,
    value: opt.score,
    text: opt.text,
    score: opt.score,
  }));

  return { questions: formattedQuestions, options };
}

/**
 * Calculates result based on student answers and real MongoDB question configs.
 */
async function calculateResultFromDb(answers, student) {
  if (!Array.isArray(answers) || answers.length === 0) {
    const error = new Error('Answers are required to submit the test');
    error.statusCode = 400;
    throw error;
  }

  const questionIds = answers.map((a) => a.questionId);
  const dbQuestions = await PersonalityQuestion.find({ _id: { $in: questionIds } }).lean();
  const questionMap = new Map(dbQuestions.map((q) => [q._id.toString(), q]));

  const rawScores = {};
  const maxScores = {};
  const scoredQuestions = [];

  for (const answerEntry of answers) {
    const qId = String(answerEntry.questionId);
    const question = questionMap.get(qId);
    if (!question) continue;

    const category = (question.category || 'general').toLowerCase();
    if (rawScores[category] === undefined) {
      rawScores[category] = 0;
      maxScores[category] = 0;
    }

    const options = question.options && question.options.length ? question.options : DEFAULT_LIKERT_OPTIONS;
    const scoresList = options.map((o) => o.score);
    const minScore = Math.min(...scoresList);
    const maxScore = Math.max(...scoresList);

    // Match selected answer by text/label or index
    let matchedOption = options.find(
      (o) => o.text.toLowerCase() === String(answerEntry.answer || '').trim().toLowerCase(),
    );
    if (!matchedOption && typeof answerEntry.optionIndex === 'number' && options[answerEntry.optionIndex]) {
      matchedOption = options[answerEntry.optionIndex];
    }
    if (!matchedOption && typeof answerEntry.score === 'number') {
      matchedOption = options.find((o) => o.score === answerEntry.score);
    }
    if (!matchedOption) {
      matchedOption = options[Math.floor(options.length / 2)] || { text: 'Neutral', score: 3 };
    }

    let finalScore = matchedOption.score;
    // Apply Reverse Scoring if configured
    if (question.reverseScoring) {
      finalScore = minScore + maxScore - finalScore;
    }

    rawScores[category] += finalScore;
    maxScores[category] += maxScore;

    scoredQuestions.push({
      questionId: qId,
      answer: matchedOption.text,
      score: finalScore,
    });
  }

  const categories = Object.keys(rawScores);
  if (categories.length === 0) {
    const error = new Error('No valid answered questions found');
    error.statusCode = 400;
    throw error;
  }

  const scores = {};
  for (const cat of categories) {
    scores[cat] = maxScores[cat] ? Math.round((rawScores[cat] / maxScores[cat]) * 100) : 0;
  }

  // Determine top dominant category
  const topCategory = categories.reduce((best, cat) => (scores[cat] > (scores[best] || 0) ? cat : best), categories[0]);
  const matchedTypeConfig = PERSONALITY_TYPES[topCategory] || {
    name: `${topCategory.charAt(0).toUpperCase() + topCategory.slice(1)} Explorer`,
    strengths: ['Analytical thinking', 'Problem solving', 'Goal oriented'],
    careers: ['Software Engineer', 'Data Analyst', 'Specialist'],
  };

  // Connect dynamically to Career Recommendation Service (no hardcoded careers or percentages!)
  let dynamicCareerMatches = [];
  try {
    const profileInput = {
      personalityType: topCategory,
      stream: student?.stream || 'Mathematics',
      subjects: student?.alResults?.map((r) => r.name) || [],
      interests: student?.interests || [],
    };
    const recommendations = await recommendCareers(profileInput, { limit: 5 });
    dynamicCareerMatches = recommendations.map((rec) => ({
      id: rec.career._id?.toString(),
      title: rec.career.title,
      category: rec.career.category,
      matchPercentage: rec.matchPercentage,
      reasons: rec.reasons || [],
    }));
  } catch (err) {
    console.warn('[Personality] Dynamic career recommendation failed, using category fallback:', err.message);
  }

  // Connect to Course Collection dynamically
  let dynamicCourseMatches = [];
  try {
    const topCareerTitles = dynamicCareerMatches.map((c) => c.title);
    const query = { isActive: true };
    if (topCareerTitles.length > 0) {
      query.$or = [
        { careerPaths: { $in: topCareerTitles } },
        { stream: student?.stream || 'Science' },
      ];
    }
    const courses = await Course.find(query).limit(5).lean();
    dynamicCourseMatches = courses.map((c) => ({
      id: c._id?.toString(),
      title: c.title,
      university: c.university,
      stream: c.stream,
      durationYears: c.durationYears,
    }));
  } catch (err) {
    console.warn('[Personality] Course matching error:', err.message);
  }

  const careerNames = dynamicCareerMatches.length > 0
    ? dynamicCareerMatches.map((c) => c.title)
    : matchedTypeConfig.careers;

  return {
    questions: scoredQuestions,
    scores,
    resultType: matchedTypeConfig.name,
    strengths: matchedTypeConfig.strengths,
    careers: careerNames,
    recommendedCareers: dynamicCareerMatches,
    recommendedCourses: dynamicCourseMatches,
    completedDate: new Date(),
  };
}

/**
 * Submits test, stores result in MongoDB, archives history, and updates Student profile.
 */
async function submitTest(userId, studentId, answers) {
  let student = null;
  if (studentId) {
    student = await Student.findOne({ _id: studentId, userId });
  }
  if (!student) {
    student = await Student.findOne({ userId });
  }
  if (!student) {
    const error = new Error('Student profile not found');
    error.statusCode = 404;
    throw error;
  }

  const result = await calculateResultFromDb(answers, student);

  const existingTest = await PersonalityTest.findOne({ studentId: student._id });
  let history = existingTest?.history || [];
  if (existingTest && existingTest.resultType) {
    // Archive previous attempt into history
    history.push({
      resultType: existingTest.resultType,
      scores: existingTest.scores,
      strengths: existingTest.strengths,
      careers: existingTest.careers,
      recommendedCareers: existingTest.recommendedCareers || [],
      recommendedCourses: existingTest.recommendedCourses || [],
      completedDate: existingTest.completedDate || existingTest.updatedAt || new Date(),
    });
  }

  const test = await PersonalityTest.findOneAndUpdate(
    { studentId: student._id },
    {
      studentId: student._id,
      questions: result.questions,
      scores: result.scores,
      resultType: result.resultType,
      strengths: result.strengths,
      careers: result.careers,
      recommendedCareers: result.recommendedCareers,
      recommendedCourses: result.recommendedCourses,
      completedDate: result.completedDate,
      history,
    },
    { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true },
  );

  // Update Student personalityResult
  student.personalityResult = {
    category: result.resultType,
    strengths: result.strengths,
    scores: result.scores,
    completedAt: result.completedDate,
  };
  await student.save();

  return test;
}

/**
 * Retrieves latest result for student.
 */
async function getResult(userId, studentId) {
  let student = null;
  if (studentId) {
    student = await Student.findOne({ _id: studentId, userId });
  }
  if (!student) {
    student = await Student.findOne({ userId });
  }
  if (!student) {
    const error = new Error('Student profile not found');
    error.statusCode = 404;
    throw error;
  }

  const test = await PersonalityTest.findOne({ studentId: student._id });
  if (!test) {
    const error = new Error('No personality test result found for this student');
    error.statusCode = 404;
    throw error;
  }
  return test;
}

/**
 * Retrieves test result history for student.
 */
async function getHistory(userId, studentId) {
  const result = await getResult(userId, studentId);
  const historyList = [
    {
      resultType: result.resultType,
      scores: result.scores,
      strengths: result.strengths,
      careers: result.careers,
      completedDate: result.completedDate,
      isLatest: true,
    },
    ...(result.history || []).map((h) => ({
      resultType: h.resultType,
      scores: h.scores,
      strengths: h.strengths,
      careers: h.careers,
      completedDate: h.completedDate,
      isLatest: false,
    })),
  ];
  return historyList;
}

// =========================================================================
// ADMIN CRUD & MANAGEMENT OPERATIONS
// =========================================================================

/**
 * Admin: List questions with search, filters and ordering.
 */
async function listAdminQuestions({ search, type, category, status } = {}) {
  await ensureDefaultQuestions();

  const query = {};

  if (search && search.trim()) {
    query.questionText = { $regex: search.trim(), $options: 'i' };
  }

  if (type && type !== 'all') {
    query.type = type.toLowerCase();
  }

  if (category && category !== 'all') {
    query.category = category.toLowerCase();
  }

  if (status === 'active') {
    query.isActive = true;
  } else if (status === 'inactive') {
    query.isActive = false;
  }

  const questions = await PersonalityQuestion.find(query)
    .sort({ displayOrder: 1, createdAt: 1 })
    .lean();

  return questions;
}

/**
 * Admin: Create a new question.
 */
async function createAdminQuestion(data) {
  const text = (data.questionText || data.text || '').trim();
  if (!text) {
    const error = new Error('Question text is required');
    error.statusCode = 400;
    throw error;
  }

  const category = (data.category || '').trim().toLowerCase();
  if (!category) {
    const error = new Error('Category is required');
    error.statusCode = 400;
    throw error;
  }

  const type = (data.type || 'personality').trim().toLowerCase();

  let options = data.options;
  if (!Array.isArray(options) || options.length < 2) {
    options = DEFAULT_LIKERT_OPTIONS;
  } else {
    options = options.map((opt) => ({
      text: String(opt.text || opt.label || '').trim(),
      score: Number(opt.score ?? opt.value ?? 1),
    }));
  }

  let displayOrder = Number(data.displayOrder);
  if (isNaN(displayOrder) || displayOrder <= 0) {
    const highest = await PersonalityQuestion.findOne().sort({ displayOrder: -1 }).select('displayOrder');
    displayOrder = (highest?.displayOrder || 0) + 1;
  }

  const question = new PersonalityQuestion({
    questionText: text,
    type,
    category,
    answerType: data.answerType || 'likert',
    options,
    reverseScoring: Boolean(data.reverseScoring),
    displayOrder,
    isActive: data.isActive !== undefined ? Boolean(data.isActive) : true,
  });

  await question.save();
  return question;
}

/**
 * Admin: Update question.
 */
async function updateAdminQuestion(id, data) {
  const question = await PersonalityQuestion.findById(id);
  if (!question) {
    const error = new Error('Question not found');
    error.statusCode = 404;
    throw error;
  }

  if (data.questionText !== undefined || data.text !== undefined) {
    const text = String(data.questionText || data.text || '').trim();
    if (!text) {
      const error = new Error('Question text cannot be empty');
      error.statusCode = 400;
      throw error;
    }
    question.questionText = text;
  }

  if (data.category !== undefined) {
    const cat = String(data.category).trim().toLowerCase();
    if (!cat) {
      const error = new Error('Category cannot be empty');
      error.statusCode = 400;
      throw error;
    }
    question.category = cat;
  }

  if (data.type !== undefined) question.type = String(data.type).trim().toLowerCase();
  if (data.answerType !== undefined) question.answerType = data.answerType;
  if (data.reverseScoring !== undefined) question.reverseScoring = Boolean(data.reverseScoring);
  if (data.displayOrder !== undefined) question.displayOrder = Number(data.displayOrder) || question.displayOrder;
  if (data.isActive !== undefined) question.isActive = Boolean(data.isActive);

  if (Array.isArray(data.options) && data.options.length >= 2) {
    question.options = data.options.map((opt) => ({
      text: String(opt.text || opt.label || '').trim(),
      score: Number(opt.score ?? opt.value ?? 1),
    }));
  }

  await question.save();
  return question;
}

/**
 * Admin: Delete question or safely deactivate.
 */
async function deleteAdminQuestion(id, permanent = false) {
  const question = await PersonalityQuestion.findById(id);
  if (!question) {
    const error = new Error('Question not found');
    error.statusCode = 404;
    throw error;
  }

  if (permanent) {
    await PersonalityQuestion.findByIdAndDelete(id);
    return { success: true, message: 'Question permanently deleted' };
  }

  // Safe toggle/deactivate
  question.isActive = false;
  await question.save();
  return { success: true, message: 'Question deactivated', question };
}

/**
 * Admin: Set question active status.
 */
async function setQuestionStatusAdmin(id, isActive) {
  const question = await PersonalityQuestion.findById(id);
  if (!question) {
    const error = new Error('Question not found');
    error.statusCode = 404;
    throw error;
  }
  question.isActive = Boolean(isActive);
  await question.save();
  return question;
}

/**
 * Admin: Aggregate test analytics.
 */
async function getAdminAnalytics() {
  const totalQuestions = await PersonalityQuestion.countDocuments();
  const activeQuestions = await PersonalityQuestion.countDocuments({ isActive: true });
  const totalTests = await PersonalityTest.countDocuments();

  const typeDistribution = await PersonalityTest.aggregate([
    { $group: { _id: '$resultType', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);

  const mostCommonType = typeDistribution[0]?._id || 'Analytical Explorer';

  return {
    totalQuestions,
    activeQuestions,
    inactiveQuestions: totalQuestions - activeQuestions,
    totalCompletedTests: totalTests,
    mostCommonType,
    typeDistribution,
  };
}

module.exports = {
  ensureDefaultQuestions,
  getQuestionSet,
  submitTest,
  getResult,
  getHistory,
  listAdminQuestions,
  createAdminQuestion,
  updateAdminQuestion,
  deleteAdminQuestion,
  setQuestionStatusAdmin,
  getAdminAnalytics,
};
