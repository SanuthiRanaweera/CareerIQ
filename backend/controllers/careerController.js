const Career = require('../models/Career');

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
 * GET /api/careers
 * Returns every career, alphabetically by title so the list screen has a
 * stable, predictable order. Search and category filtering are added later.
 */
async function getCareers(_req, res, next) {
	try {
		const careers = await Career.find().sort({ title: 1 });
		return res.json({ success: true, count: careers.length, data: careers });
	} catch (error) {
		return next(error);
	}
}

module.exports = { createCareer, getCareers };
