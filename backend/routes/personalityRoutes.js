const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/personalityController');

const router = express.Router();
router.use(protect);
router.get('/questions', controller.getQuestions);
router.post('/submit', controller.submitTest);
router.get('/result/:studentId', controller.getResult);

module.exports = router;
