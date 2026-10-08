const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const { adminOnly } = require('../middleware/adminMiddleware');
const controller = require('../controllers/personalityController');

const router = express.Router();

router.use(protect, adminOnly);

router.get('/analytics', controller.getAdminAnalytics);
router.get('/', controller.listAdminQuestions);
router.post('/', controller.createAdminQuestion);
router.put('/:id', controller.updateAdminQuestion);
router.delete('/:id', controller.deleteAdminQuestion);
router.patch('/:id/status', controller.setQuestionStatus);

module.exports = router;

