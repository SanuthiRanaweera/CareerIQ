const mongoose = require('mongoose');
const Career = require('../models/Career');
const SavedCareer = require('../models/SavedCareer');
const { PRIORITIES } = SavedCareer;

const NOT_FOUND = { success: false, message: 'Saved career not found' };

function isValidId(id) {
	return mongoose.Types.ObjectId.isValid(id);
}

/**
 * POST /api/saved-careers
 * Body: { careerId, note?, priority? }
 * Adds a career to the signed-in student's shortlist. Saving the same career
 * twice is reported as a 409 rather than creating a duplicate.
 */
async function saveCareer(req, res, next) {
	try {
		const { careerId, note, priority } = req.body || {};
		if (!isValidId(careerId)) return res.status(400).json({ success: false, message: 'A valid careerId is required' });
		if (priority !== undefined && !PRIORITIES.includes(priority)) {
			return res.status(400).json({ success: false, message: `priority must be one of: ${PRIORITIES.join(', ')}` });
		}
		if (!(await Career.exists({ _id: careerId }))) {
			return res.status(404).json({ success: false, message: 'Career not found' });
		}

		const saved = await SavedCareer.create({ userId: req.user.userId, career: careerId, note, priority });
		await saved.populate('career');
		return res.status(201).json({ success: true, message: 'Career saved to your shortlist', data: saved });
	} catch (error) {
		if (error.code === 11000) {
			return res.status(409).json({ success: false, message: 'This career is already on your shortlist' });
		}
		return next(error);
	}
}

/**
 * GET /api/saved-careers?priority=
 * The signed-in student's shortlist, most important first and then newest
 * first. `priority` is optional.
 */
async function getSavedCareers(req, res, next) {
	try {
		const filter = { userId: req.user.userId };
		const priority = (req.query.priority || '').trim();
		if (priority) {
			if (!PRIORITIES.includes(priority)) {
				return res.status(400).json({ success: false, message: `priority must be one of: ${PRIORITIES.join(', ')}` });
			}
			filter.priority = priority;
		}

		const saved = await SavedCareer.find(filter).populate('career').sort({ createdAt: -1 });
		const rank = (item) => PRIORITIES.indexOf(item.priority);
		// Stable sort keeps newest-first within each priority.
		const data = saved.filter((item) => item.career).sort((a, b) => rank(a) - rank(b));
		return res.json({ success: true, count: data.length, data });
	} catch (error) {
		return next(error);
	}
}

/**
 * PUT /api/saved-careers/:id
 * Body: { note?, priority? }
 * Edits the student's own note and priority. Only those two fields can change.
 */
async function updateSavedCareer(req, res, next) {
	try {
		if (!isValidId(req.params.id)) return res.status(404).json(NOT_FOUND);
		const { note, priority } = req.body || {};
		if (priority !== undefined && !PRIORITIES.includes(priority)) {
			return res.status(400).json({ success: false, message: `priority must be one of: ${PRIORITIES.join(', ')}` });
		}

		const changes = {};
		if (note !== undefined) changes.note = note;
		if (priority !== undefined) changes.priority = priority;

		// Scoped to the signed-in user, so someone else's entry looks "not found".
		const saved = await SavedCareer.findOneAndUpdate(
			{ _id: req.params.id, userId: req.user.userId },
			changes,
			{ returnDocument: 'after', runValidators: true },
		).populate('career');
		if (!saved) return res.status(404).json(NOT_FOUND);
		return res.json({ success: true, message: 'Shortlist entry updated', data: saved });
	} catch (error) {
		return next(error);
	}
}

/**
 * DELETE /api/saved-careers/:id
 * Removes a career from the signed-in student's shortlist.
 */
async function deleteSavedCareer(req, res, next) {
	try {
		if (!isValidId(req.params.id)) return res.status(404).json(NOT_FOUND);
		const saved = await SavedCareer.findOneAndDelete({ _id: req.params.id, userId: req.user.userId });
		if (!saved) return res.status(404).json(NOT_FOUND);
		return res.json({ success: true, message: 'Removed from your shortlist' });
	} catch (error) {
		return next(error);
	}
}

module.exports = { saveCareer, getSavedCareers, updateSavedCareer, deleteSavedCareer };
