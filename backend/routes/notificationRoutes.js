const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/notificationController');

const router = express.Router();
router.use(protect);
router.get('/admin/students', controller.adminOnly, controller.listRecipients);
router.post('/admin/send', controller.adminOnly, controller.sendNotification);
router.get('/', controller.listMyNotifications);
router.patch('/:id/read', controller.markAsRead);

module.exports = router;