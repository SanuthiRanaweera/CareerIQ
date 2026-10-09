const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const controller = require('../controllers/savedCareerController');

const router = express.Router();

// Every route works on the signed-in user's own shortlist.
router.use(protect);

router.post('/', controller.saveCareer);
router.get('/', controller.getSavedCareers);
router.put('/:id', controller.updateSavedCareer);
router.delete('/:id', controller.deleteSavedCareer);

module.exports = router;
