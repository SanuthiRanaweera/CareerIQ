const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/studentController');

const router = express.Router();
router.use(protect);
router.get('/me', controller.getMyStudent);
router.post('/', controller.createStudent);
router.get('/:id', controller.getStudent);
router.put('/:id', controller.updateStudent);
router.delete('/:id', controller.deleteStudent);

module.exports = router;
