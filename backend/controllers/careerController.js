const mongoose = require('mongoose');
const Career = require('../models/Career');

// A malformed id can never match a career, so it is treated as "not found"
// rather than being allowed to reach Mongoose and throw a CastError (which the
// shared error middleware would report as a 500).
function isValidId(id) {
	return mongoose.Types.ObjectId.isValid(id);
}

const NOT_FOUND = { success: false, message: 'Career not found' };

// Escapes a user-typed search term so characters such as ( * or ? are matched
// literally instead of being interpreted as regular-expression syntax, which
// would otherwise either crash the query or return surprising results.
function escapeRegex(text) {
	return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * POST /api/careers
 * Creates a new career. Career titles are unique, so a repeated title is
 * reported as a 409 conflict rather than surfacing a raw MongoDB duplicate-key
 * error, giving the admin form a message it can show as-is.
 */
async function createCareer(req, res, next) {
	try {
		const career = await Career.create(req.body);
		return res.status(201).json({ success: true, message: 'Career created successfully', data: career });
	} catch (error) {
		if (error.code === 11000) {
			return res.status(409).json({ success: false, message: 'A career with this title already exists' });
		}
		return next(error);
	}
}

/**
 * GET /api/careers?search=&category=
 * Returns careers alphabetically by title so the list screen has a stable
 * order. Both query parameters are optional and combine with AND: searching
 * "data" inside the "Finance & Banking" category returns only the finance
 * careers that match the term.
 */
async function getCareers(req, res, next) {
	try {
		const search = (req.query.search || '').trim();
		const category = (req.query.category || '').trim();
		const filter = {};

		// "All" is the default chip on the careers screen and means "no filter",
		// so it is ignored rather than matched against a real category name.
		if (category && category.toLowerCase() !== 'all') {
			filter.category = new RegExp(`^${escapeRegex(category)}$`, 'i');
		}

		// Partial, case-insensitive match so the list narrows while the student
		// is still typing. Skills are included so searching "python" works.
		if (search) {
			const term = new RegExp(escapeRegex(search), 'i');
			filter.$or = [{ title: term }, { category: term }, { description: term }, { requiredSkills: term }];
		}

		const careers = await Career.find(filter).sort({ title: 1 });
		return res.json({ success: true, count: careers.length, data: careers });
	} catch (error) {
		return next(error);
	}
}

/**
 * GET /api/careers/categories
 * Distinct category names, used to build the filter chips on the careers
 * screen so the chip list always reflects the data actually stored.
 */
async function getCareerCategories(_req, res, next) {
	try {
		const categories = await Career.distinct('category');
		return res.json({ success: true, data: categories.sort((a, b) => a.localeCompare(b)) });
	} catch (error) {
		return next(error);
	}
}

/**
 * GET /api/careers/:id
 * Returns a single career with its full detail, including the pathway steps
 * used by the career pathway screen.
 */
async function getCareerById(req, res, next) {
	try {
		if (!isValidId(req.params.id)) return res.status(404).json(NOT_FOUND);
		const career = await Career.findById(req.params.id);
		if (!career) return res.status(404).json(NOT_FOUND);
		return res.json({ success: true, data: career });
	} catch (error) {
		return next(error);
	}
}

/**
 * PUT /api/careers/:id
 * Updates a career. `runValidators` keeps edits held to the same rules as
 * creation, so the admin edit form cannot save a career the create form
 * would have rejected.
 */
async function updateCareer(req, res, next) {
	try {
		if (!isValidId(req.params.id)) return res.status(404).json(NOT_FOUND);
		const career = await Career.findByIdAndUpdate(req.params.id, req.body, { returnDocument: 'after', runValidators: true });
		if (!career) return res.status(404).json(NOT_FOUND);
		return res.json({ success: true, message: 'Career updated successfully', data: career });
	} catch (error) {
		if (error.code === 11000) {
			return res.status(409).json({ success: false, message: 'A career with this title already exists' });
		}
		return next(error);
	}
}

/**
 * DELETE /api/careers/:id
 * Removes a career. The confirmation step lives in the admin UI; by the time a
 * request reaches here the deletion has already been confirmed by the user.
 */
async function deleteCareer(req, res, next) {
	try {
		if (!isValidId(req.params.id)) return res.status(404).json(NOT_FOUND);
		const career = await Career.findByIdAndDelete(req.params.id);
		if (!career) return res.status(404).json(NOT_FOUND);
		return res.json({ success: true, message: 'Career deleted successfully' });
	} catch (error) {
		return next(error);
	}
}

module.exports = { createCareer, getCareers, getCareerCategories, getCareerById, updateCareer, deleteCareer };
