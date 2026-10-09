const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
	listCourses,
	getCourse,
	createCourse,
	updateCourse,
	deleteCourse,
	cleanFakeCourses,
} = require('../controllers/courseController');

const router = express.Router();

function adminOnly(req, res, next) {
	if (req.user?.role !== 'admin') {
		return res.status(403).json({ success: false, message: 'Administrator access required' });
	}
	return next();
}

router.get('/', listCourses);
router.get('/admin', protect, adminOnly, (req, _res, next) => {
	req.includeInactive = true;
	return next();
}, listCourses);
router.get('/:id', getCourse);
router.post('/', protect, adminOnly, createCourse);
router.put('/:id', protect, adminOnly, updateCourse);
router.delete('/:id', protect, adminOnly, deleteCourse);

module.exports = router;
