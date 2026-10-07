const mongoose = require('mongoose');
const Course = require('../models/Course');

const editableFields = [
	'title', 'university', 'stream', 'degreeType', 'description',
	'durationYears', 'minZScore', 'subjects', 'careerPaths',
	'website', 'applicationUrl', 'isActive',
];

function courseInput(body, partial = false) {
	const input = {};
	for (const field of editableFields) {
		if (Object.hasOwn(body, field)) input[field] = body[field];
	}
	if (!partial) {
		for (const field of ['title', 'university', 'stream', 'durationYears']) {
			if (input[field] === undefined || input[field] === '') {
				throw Object.assign(new Error(`${field} is required`), { statusCode: 400 });
			}
		}
	}
	if (input.durationYears !== undefined && (!Number.isFinite(Number(input.durationYears)) || Number(input.durationYears) <= 0)) {
		throw Object.assign(new Error('Duration must be a positive number of years'), { statusCode: 400 });
	}
	if (input.minZScore !== undefined && input.minZScore !== null && input.minZScore !== '' && !Number.isFinite(Number(input.minZScore))) {
		throw Object.assign(new Error('Minimum Z-score must be a number'), { statusCode: 400 });
	}
	if (input.durationYears !== undefined) input.durationYears = Number(input.durationYears);
	if (input.minZScore === '') input.minZScore = null;
	else if (input.minZScore !== undefined && input.minZScore !== null) input.minZScore = Number(input.minZScore);
	for (const field of ['subjects', 'careerPaths']) {
		if (input[field] !== undefined && !Array.isArray(input[field])) {
			throw Object.assign(new Error(`${field} must be a list`), { statusCode: 400 });
		}
	}
	return input;
}

function escapedRegex(value) {
	return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function listCourses(req, res, next) {
	try {
		const page = Math.max(1, Number.parseInt(req.query.page, 10) || 1);
		const limit = Math.min(50, Math.max(1, Number.parseInt(req.query.limit, 10) || 20));
		const filter = req.includeInactive ? {} : { isActive: true };
		if (req.query.stream && req.query.stream !== 'All') filter.stream = req.query.stream;
		if (req.query.university) filter.university = new RegExp(escapedRegex(String(req.query.university)), 'i');
		if (req.query.search) {
			const search = new RegExp(escapedRegex(String(req.query.search)), 'i');
			filter.$or = [{ title: search }, { university: search }, { description: search }, { careerPaths: search }];
		}
		const [courses, total] = await Promise.all([
			Course.find(filter).sort({ university: 1, title: 1 }).skip((page - 1) * limit).limit(limit).lean(),
			Course.countDocuments(filter),
		]);
		res.json({ success: true, data: courses, pagination: { page, limit, total, pages: Math.ceil(total / limit) } });
	} catch (error) { next(error); }
}

async function getCourse(req, res, next) {
	try {
		if (!mongoose.isValidObjectId(req.params.id)) return res.status(404).json({ success: false, message: 'Course not found' });
		const filter = { _id: req.params.id };
		if (!req.includeInactive) filter.isActive = true;
		const course = await Course.findOne(filter).lean();
		if (!course) return res.status(404).json({ success: false, message: 'Course not found' });
		res.json({ success: true, data: course });
	} catch (error) { next(error); }
}

async function createCourse(req, res, next) {
	try {
		const course = await Course.create(courseInput(req.body));
		res.status(201).json({ success: true, data: course });
	} catch (error) { next(error); }
}

async function updateCourse(req, res, next) {
	try {
		if (!mongoose.isValidObjectId(req.params.id)) return res.status(404).json({ success: false, message: 'Course not found' });
		const course = await Course.findByIdAndUpdate(req.params.id, courseInput(req.body, true), {
			new: true,
			runValidators: true,
		});
		if (!course) return res.status(404).json({ success: false, message: 'Course not found' });
		res.json({ success: true, data: course });
	} catch (error) { next(error); }
}

async function deleteCourse(req, res, next) {
	try {
		if (!mongoose.isValidObjectId(req.params.id)) return res.status(404).json({ success: false, message: 'Course not found' });
		const course = await Course.findByIdAndUpdate(req.params.id, { isActive: false }, { new: true });
		if (!course) return res.status(404).json({ success: false, message: 'Course not found' });
		res.json({ success: true, message: 'Course archived successfully', data: course });
	} catch (error) { next(error); }
}

module.exports = { listCourses, getCourse, createCourse, updateCourse, deleteCourse };
