const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const { adminOnly } = require('../middleware/adminMiddleware');
const controller = require('../controllers/personalityController');

const router = express.Router();

router.use(protect);

// --- STUDENT ENDPOINTS ---
router.get('/questions', controller.getQuestions);
router.post('/submit', controller.submitTest);
router.get('/my-result', controller.getResult);
router.get('/result/:studentId', controller.getResult);
router.get('/history', controller.getHistory);
router.get('/history/:studentId', controller.getHistory);

// --- ADMIN QUESTION MANAGEMENT ENDPOINTS ---
router.get('/admin/questions', adminOnly, controller.listAdminQuestions);
router.get('/admin/analytics', adminOnly, controller.getAdminAnalytics);
router.post('/admin/questions', adminOnly, controller.createAdminQuestion);
router.put('/admin/questions/:id', adminOnly, controller.updateAdminQuestion);
router.delete('/admin/questions/:id', adminOnly, controller.deleteAdminQuestion);
router.patch('/admin/questions/:id/status', adminOnly, controller.setQuestionStatus);

module.exports = router;
