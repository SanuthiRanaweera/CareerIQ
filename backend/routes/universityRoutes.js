const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const { adminOnly } = require('../middleware/adminMiddleware');
const controller = require('../controllers/universityController');

const router = express.Router();

router.use(protect);

// University's own profile and dashboard routes
router.get('/dashboard', controller.getUniversityDashboard);
router.get('/profile', controller.getUniversityProfile);
router.put('/profile', controller.updateUniversityProfile);
router.get('/courses', controller.getUniversityCourses);
router.get('/analytics', controller.getUniversityAnalytics);

// University comparison route (Accessible to authenticated users/students)
router.get('/compare', controller.getCompareUniversities);

// Admin statistics route
router.get('/statistics', adminOnly, controller.getUniversityStatistics);

// University listing & details (Accessible to authenticated users/students and admins)
router.get('/', controller.listUniversities);
router.get('/:id', controller.getUniversity);
router.get('/:id/courses', controller.getUniversityCoursesById);

// Admin-only University Management modification routes
router.post('/', adminOnly, controller.createUniversity);
router.post('/verify-otp', adminOnly, controller.verifyUniversityOtp);
router.post('/resend-otp', adminOnly, controller.resendUniversityOtp);
router.put('/:id', adminOnly, controller.updateUniversity);
router.delete('/:id', adminOnly, controller.deleteUniversity);
router.patch('/:id/status', adminOnly, controller.updateUniversityStatus);

module.exports = router;
