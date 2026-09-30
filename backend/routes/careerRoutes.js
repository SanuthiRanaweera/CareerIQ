const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/careerController');

const router = express.Router();

/**
 * Every career route requires a signed-in user, matching the rest of the API.
 * `protect` populates req.user with { userId, email, role }.
 */
router.use(protect);

/**
 * Writes are restricted to admin accounts, because creating, editing and
 * deleting careers is done from the admin "Manage careers" screen. Students
 * only ever read. Defined here rather than in shared middleware so the Career
 * module stays self-contained.
 */
function adminOnly(req, res, next) {
	if (req.user?.role !== 'admin') {
		return res.status(403).json({ success: false, message: 'Admin access is required for this action' });
	}
	return next();
}

// --- Student-facing (read) ---
router.get('/', controller.getCareers);
router.get('/:id', controller.getCareerById);

// --- Admin-facing (write) ---
router.post('/', adminOnly, controller.createCareer);
router.put('/:id', adminOnly, controller.updateCareer);
router.delete('/:id', adminOnly, controller.deleteCareer);

module.exports = router;
