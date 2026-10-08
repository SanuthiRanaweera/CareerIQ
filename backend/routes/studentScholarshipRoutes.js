const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/scholarshipController');

const router = express.Router();

router.use(protect);

router.get('/:id', controller.getStudentApplicationById);
router.get('/', controller.listStudentApplications);

module.exports = router;

