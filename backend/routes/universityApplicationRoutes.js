const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/scholarshipController');

const router = express.Router();

router.use(protect);

router.get('/', controller.getUniversityApplications);
router.get('/:id', controller.getUniversityApplicationById);
router.patch('/:id/status', controller.updateApplicationStatus);

module.exports = router;

