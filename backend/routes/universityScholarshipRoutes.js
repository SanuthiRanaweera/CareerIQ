const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/scholarshipController');

const router = express.Router();

router.use(protect);

// Statistics
router.get('/statistics', controller.getUniversityScholarshipStats);

// Single scholarship applications
router.get('/:id/applications', controller.getUniversityApplications);

// Single scholarship operations
router.get('/:id', controller.getUniversityScholarshipById);
router.put('/:id', controller.updateScholarship);
router.delete('/:id', controller.deleteScholarship);
router.patch('/:id/status', controller.updateScholarshipStatus);

// CRUD Root
router.get('/', controller.getUniversityScholarships);
router.post('/', controller.createScholarship);

module.exports = router;
