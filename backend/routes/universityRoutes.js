const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const { adminOnly } = require('../middleware/adminMiddleware');
const controller = require('../controllers/universityController');

const router = express.Router();

router.use(protect);

// University's own profile routes
router.get('/profile', controller.getUniversityProfile);
router.put('/profile', controller.updateUniversityProfile);

// Admin-only University Management routes
router.use(adminOnly);

router.get('/statistics', controller.getUniversityStatistics);
router.get('/', controller.listUniversities);
router.post('/', controller.createUniversity);
router.post('/verify-otp', controller.verifyUniversityOtp);
router.post('/resend-otp', controller.resendUniversityOtp);
router.get('/:id', controller.getUniversity);
router.put('/:id', controller.updateUniversity);
router.delete('/:id', controller.deleteUniversity);
router.patch('/:id/status', controller.updateUniversityStatus);

module.exports = router;
