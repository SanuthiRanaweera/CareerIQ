const personalityService = require('../services/personalityService');

// --- STUDENT ACTIONS ---

async function getQuestions(_req, res, next) {
  try {
    const data = await personalityService.getQuestionSet();
    return res.json({ success: true, data, questions: data.questions, options: data.options });
  } catch (error) {
    return next(error);
  }
}

async function submitTest(req, res, next) {
  try {
    const { studentId, answers } = req.body;
    if (!Array.isArray(answers) || answers.length === 0) {
      return res.status(400).json({ success: false, message: 'answers array is required' });
    }
    const result = await personalityService.submitTest(req.user.userId, studentId, answers);
    return res.status(201).json({
      success: true,
      message: 'Personality test submitted successfully',
      data: result,
      result,
    });
  } catch (error) {
    return next(error);
  }
}

async function getResult(req, res, next) {
  try {
    const studentId = req.params.studentId || req.query.studentId;
    const result = await personalityService.getResult(req.user.userId, studentId);
    return res.json({ success: true, data: result, result });
  } catch (error) {
    return next(error);
  }
}

async function getHistory(req, res, next) {
  try {
    const studentId = req.params.studentId || req.query.studentId;
    const history = await personalityService.getHistory(req.user.userId, studentId);
    return res.json({ success: true, data: history });
  } catch (error) {
    return next(error);
  }
}

// --- ADMIN ACTIONS ---

async function listAdminQuestions(req, res, next) {
  try {
    const { search, type, category, status } = req.query;
    const questions = await personalityService.listAdminQuestions({ search, type, category, status });
    return res.json({ success: true, data: questions, questions });
  } catch (error) {
    return next(error);
  }
}

async function createAdminQuestion(req, res, next) {
  try {
    const question = await personalityService.createAdminQuestion(req.body);
    return res.status(201).json({
      success: true,
      message: 'Question created successfully',
      data: question,
      question,
    });
  } catch (error) {
    return next(error);
  }
}

async function updateAdminQuestion(req, res, next) {
  try {
    const question = await personalityService.updateAdminQuestion(req.params.id, req.body);
    return res.json({
      success: true,
      message: 'Question updated successfully',
      data: question,
      question,
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteAdminQuestion(req, res, next) {
  try {
    const permanent = req.query.permanent === 'true';
    const result = await personalityService.deleteAdminQuestion(req.params.id, permanent);
    return res.json(result);
  } catch (error) {
    return next(error);
  }
}

async function setQuestionStatus(req, res, next) {
  try {
    const { isActive, status } = req.body;
    const active = isActive !== undefined ? isActive : status === 'active';
    const question = await personalityService.setQuestionStatusAdmin(req.params.id, active);
    return res.json({
      success: true,
      message: `Question status updated to ${question.isActive ? 'active' : 'inactive'}`,
      data: question,
    });
  } catch (error) {
    return next(error);
  }
}

async function getAdminAnalytics(_req, res, next) {
  try {
    const analytics = await personalityService.getAdminAnalytics();
    return res.json({ success: true, data: analytics });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  getQuestions,
  submitTest,
  getResult,
  getHistory,
  listAdminQuestions,
  createAdminQuestion,
  updateAdminQuestion,
  deleteAdminQuestion,
  setQuestionStatus,
  getAdminAnalytics,
};
