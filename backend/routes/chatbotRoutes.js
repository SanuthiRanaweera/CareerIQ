const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/chatbotController');

const router = express.Router();
const requests = new Map();
const windowMs = 10 * 60 * 1000;
const maxRequests = 20;

function rateLimit(req, res, next) {
  const key = String(req.user.userId);
  const now = Date.now();
  const timestamps = (requests.get(key) || []).filter((time) => now - time < windowMs);
  if (timestamps.length >= maxRequests) {
    return res.status(429).json({ success: false, message: 'You have reached the chat limit. Please try again soon.' });
  }
  timestamps.push(now);
  requests.set(key, timestamps);
  return next();
}

router.use(protect);
router.get('/history', controller.getHistory);
router.post('/messages', rateLimit, controller.sendMessage);

module.exports = router;
