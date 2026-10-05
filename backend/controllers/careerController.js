const mongoose = require('mongoose');
const Career = require('../models/Career');
const { AL_STREAMS, PERSONALITY_TYPES, WORK_STYLES } = require('../data/careerOptions');
const careerRecommendationService = require('../services/careerRecommendationService');

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

/**
 * Resolves a submitted answer against an allowed option list, ignoring case.
 * Returns the canonical spelling so the scoring service and the response both
 * use the project's own vocabulary rather than whatever the client sent.
 * An empty answer is valid: the recommendation form does not force every field.
 */
function matchOption(value, allowedValues) {
	if (value === undefined || value === null || String(value).trim() === '') return { valid: true, value: '' };
	const match = allowedValues.find((allowed) => allowed.toLowerCase() === String(value).trim().toLowerCase());
	return match ? { valid: true, value: match } : { valid: false, value: '' };
}

/** Keeps only non-empty strings, so stray nulls from the form cannot reach the scorer. */
function toStringList(value) {
	if (!Array.isArray(value)) return [];
	return value.filter((item) => typeof item === 'string' && item.trim()).map((item) => item.trim());
}

/**
 * POST /api/careers/recommend
 *
 * Scores every career against the submitted answers and returns them ranked by
 * match percentage. The request body is a plain student profile object, so the
 * same endpoint will work unchanged once real student records replace the form.
 *
 * Body: { stream?, subjects?: [], interests?: [], personalityType?, workStyle?, limit? }
 */
async function getRecommendations(req, res, next) {
	try {
		const body = req.body || {};

		// Guard the two list fields explicitly: a client sending a bare string
		// instead of an array is a mistake worth reporting rather than ignoring.
		for (const field of ['interests', 'subjects']) {
			if (body[field] !== undefined && !Array.isArray(body[field])) {
				return res.status(400).json({ success: false, message: `${field} must be an array` });
			}
		}

		const stream = matchOption(body.stream, AL_STREAMS);
		if (!stream.valid) {
			return res.status(400).json({ success: false, message: `stream must be one of: ${AL_STREAMS.join(', ')}` });
		}
		const personalityType = matchOption(body.personalityType, PERSONALITY_TYPES);
		if (!personalityType.valid) {
			return res.status(400).json({ success: false, message: `personalityType must be one of: ${PERSONALITY_TYPES.join(', ')}` });
		}
		const workStyle = matchOption(body.workStyle, WORK_STYLES);
		if (!workStyle.valid) {
			return res.status(400).json({ success: false, message: `workStyle must be one of: ${WORK_STYLES.join(', ')}` });
		}

		const profile = {
			stream: stream.value,
			subjects: toStringList(body.subjects),
			interests: toStringList(body.interests),
			personalityType: personalityType.value,
			workStyle: workStyle.value,
		};

		// A profile with nothing filled in would rank every career at 0%, which
		// is a confusing result to show. Ask for at least one answer instead.
		const hasAnyAnswer = Boolean(profile.stream || profile.personalityType || profile.workStyle)
			|| profile.subjects.length > 0
			|| profile.interests.length > 0;
		if (!hasAnyAnswer) {
			return res.status(400).json({ success: false, message: 'Please answer at least one question to get recommendations' });
		}

		const limit = Number.isInteger(body.limit) && body.limit > 0 ? Math.min(body.limit, 50) : undefined;
		const matches = await careerRecommendationService.recommendCareers(profile, { limit });

		// The normalised profile is echoed back so the results screen can show
		// what the ranking was actually based on.
		return res.json({ success: true, count: matches.length, profile, data: matches });
	} catch (error) {
		return next(error);
	}
}

module.exports = {
	createCareer,
	getCareers,
	getCareerCategories,
	getCareerById,
	updateCareer,
	deleteCareer,
	getRecommendations,
};
