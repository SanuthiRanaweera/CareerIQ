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
router.get('/messages', controller.listMessages);
router.post('/messages', limitMessages, controller.sendMessage);

module.exports = router;