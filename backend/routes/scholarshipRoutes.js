const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/scholarshipController');

const router = express.Router();

// ==================================================
// 1. PUBLIC / STUDENT SCHOLARSHIP DISCOVERY
// ==================================================
router.get('/', protect, controller.listScholarships);
router.get('/:id', protect, controller.getScholarshipById);
router.post('/:id/apply', protect, controller.applyForScholarship);

module.exports = router;

