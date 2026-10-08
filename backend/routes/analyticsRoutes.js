const express = require('express');
const { protectOptional } = require('../middleware/authMiddleware');
const controller = require('../controllers/analyticsController');

const router = express.Router();

router.post('/track', protectOptional, controller.trackAnalyticsEvent);

module.exports = router;

