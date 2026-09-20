const PersonalityTest = require('../models/PersonalityTest');
const Student = require('../models/Student');
const { QUESTIONS, ANSWER_SCORES, ANSWER_OPTIONS, CATEGORIES } = require('../data/personalityQuestions');
const PERSONALITY_TYPES = require('../data/personalityTypes');

function getQuestionSet() {
	return { questions: QUESTIONS.map(({ id, text }) => ({ id, text })), options: ANSWER_OPTIONS };
}

function calculateResult(answers) {
	if (!Array.isArray(answers) || answers.length === 0) {
		const error = new Error('Answers are required');
		error.statusCode = 400;
		throw error;
	}

	const answerByQuestionId = new Map(answers.map((entry) => [entry.questionId, entry.answer]));
	const rawScores = Object.fromEntries(CATEGORIES.map((category) => [category, 0]));
	const maxScores = Object.fromEntries(CATEGORIES.map((category) => [category, 0]));
	const scoredQuestions = [];

	for (const question of QUESTIONS) {
		const answer = answerByQuestionId.get(question.id);
		const points = ANSWER_SCORES[answer];
		if (points === undefined) {
			const error = new Error(`Missing or invalid answer for question ${question.id}`);
			error.statusCode = 400;
			throw error;
		}
		const weightedScore = points * question.weight;
		rawScores[question.category] += weightedScore;
		maxScores[question.category] += 5 * question.weight;
		scoredQuestions.push({ questionId: question.id, answer, score: weightedScore });
	}

	const scores = Object.fromEntries(
		CATEGORIES.map((category) => [
			category,
			maxScores[category] ? Math.round((rawScores[category] / maxScores[category]) * 100) : 0,
		]),
	);

	const topCategory = CATEGORIES.reduce((best, category) => (scores[category] > scores[best] ? category : best), CATEGORIES[0]);
	const personalityType = PERSONALITY_TYPES[topCategory];

	return {
		questions: scoredQuestions,
		scores,
		resultType: personalityType.name,
		strengths: personalityType.strengths,
		careers: personalityType.careers,
		completedDate: new Date(),
	};
}

async function submitTest(userId, studentId, answers) {
	const student = await Student.findOne({ _id: studentId, userId });
	if (!student) {
		const error = new Error('Student profile not found');
		error.statusCode = 404;
		throw error;
	}

	const result = calculateResult(answers);

	const test = await PersonalityTest.findOneAndUpdate(
		{ studentId: student._id },
		{ studentId: student._id, ...result },
		{ new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true },
	);

	student.personalityResult = {
		category: result.resultType,
		strengths: result.strengths,
		scores: result.scores,
		completedAt: result.completedDate,
	};
	await student.save();

	return test;
}

async function getResult(userId, studentId) {
	const student = await Student.findOne({ _id: studentId, userId });
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

module.exports = { getQuestionSet, calculateResult, submitTest, getResult };
