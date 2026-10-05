const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const { adminOnly } = require('../middleware/adminMiddleware');
const {
  createUniversity,
  listUniversities,
  getUniversity,
  updateUniversity,
  deleteUniversity,
  getUniversityProfile,
  updateUniversityProfile,
} = require('../controllers/universityController');

const router = express.Router();

router.post('/', protect, adminOnly, createUniversity);
router.get('/', protect, adminOnly, listUniversities);
router.get('/profile', protect, getUniversityProfile);
router.put('/profile', protect, updateUniversityProfile);
router.get('/:id', protect, getUniversity);
router.put('/:id', protect, adminOnly, updateUniversity);
router.delete('/:id', protect, adminOnly, deleteUniversity);

module.exports = router;
