const personalityService = require('../services/personalityService');

async function getQuestions(_req, res, next) {
	try { res.json({ success: true, data: personalityService.getQuestionSet() }); }
	catch (error) { next(error); }
}

async function submitTest(req, res, next) {
	try {
		const { studentId, answers } = req.body;
		if (!studentId || !Array.isArray(answers)) {
			return res.status(400).json({ success: false, message: 'studentId and answers are required' });
		}
		const result = await personalityService.submitTest(req.user.userId, studentId, answers);
		return res.status(201).json({ success: true, message: 'Personality test submitted successfully', data: result });
	} catch (error) { return next(error); }
}

async function getResult(req, res, next) {
	try {
		const result = await personalityService.getResult(req.user.userId, req.params.studentId);
		return res.json({ success: true, data: result });
	} catch (error) { return next(error); }
}

module.exports = { getQuestions, submitTest, getResult };
