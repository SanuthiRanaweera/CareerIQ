const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/groupChatController');

const router = express.Router();
const requests = new Map();
const windowMs = 60 * 1000;
const maxMessages = 12;

function limitMessages(req, res, next) {
	const key = String(req.user.userId);
	const now = Date.now();
	const recent = (requests.get(key) || []).filter((timestamp) => now - timestamp < windowMs);
	if (recent.length >= maxMessages) {
		return res.status(429).json({ success: false, message: 'Too many messages. Please wait a moment.' });
	}
	recent.push(now);
	requests.set(key, recent);
	return next();
}

router.use(protect);
router.get('/', controller.listMessages);
router.post('/', limitMessages, controller.sendMessage);
router.put('/:id', controller.updateMessage);
router.delete('/:id', controller.deleteMessage);

// Also support /messages for robustness
router.get('/messages', controller.listMessages);
router.post('/messages', limitMessages, controller.sendMessage);
router.put('/messages/:id', controller.updateMessage);
router.delete('/messages/:id', controller.deleteMessage);

module.exports = router;
