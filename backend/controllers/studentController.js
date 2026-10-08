const Student = require('../models/Student');
const studentService = require('../services/studentService');

async function createStudent(req, res, next) {
	try {
		if (await Student.findOne({ userId: req.user.userId })) return res.status(409).json({ success: false, message: 'Student profile already exists' });
		const student = await Student.create({ ...req.body, userId: req.user.userId, email: req.user.email });
		return res.status(201).json({ success: true, message: 'Student profile created successfully', data: student });
	} catch (error) { return next(error); }
}

async function getStudent(req, res, next) {
	try { res.json({ success: true, data: await studentService.getOwnedStudent(req.user.userId, req.params.id) }); }
	catch (error) { next(error); }
}

async function getMyStudent(req, res, next) {
	try {
		const student = await Student.findOne({ userId: req.user.userId });
		if (!student) return res.status(404).json({ success: false, message: 'Student profile not found' });
		return res.json({ success: true, data: student });
	} catch (error) { return next(error); }
}

async function updateStudent(req, res, next) {
	try {
		const student = await studentService.updateOwnedStudent(req.user.userId, req.params.id, req.body);
		if (!student) return res.status(404).json({ success: false, message: 'Student profile not found' });
		return res.json({ success: true, message: 'Student profile updated successfully', data: student });
	} catch (error) { return next(error); }
}

async function deleteStudent(req, res, next) {
	try {
		const student = await Student.findOneAndDelete({ _id: req.params.id, userId: req.user.userId });
		if (!student) return res.status(404).json({ success: false, message: 'Student profile not found' });
		return res.json({ success: true, message: 'Student profile deleted successfully' });
	} catch (error) { return next(error); }
}

async function getFavoriteUniversities(req, res, next) {
	try {
		const student = await Student.findOne({ userId: req.user.userId }).populate('favoriteUniversities');
		if (!student) return res.status(404).json({ success: false, message: 'Student profile not found' });
		return res.json({ success: true, data: student.favoriteUniversities || [] });
	} catch (error) { return next(error); }
}

async function toggleFavoriteUniversity(req, res, next) {
	try {
		const { universityId } = req.params;
		const student = await Student.findOne({ userId: req.user.userId });
		if (!student) return res.status(404).json({ success: false, message: 'Student profile not found' });

		student.favoriteUniversities = student.favoriteUniversities || [];
		const index = student.favoriteUniversities.findIndex((id) => id.toString() === universityId.toString());
		let isFavorite = false;
		if (index >= 0) {
			student.favoriteUniversities.splice(index, 1);
			isFavorite = false;
		} else {
			student.favoriteUniversities.push(universityId);
			isFavorite = true;
		}
		await student.save();

		if (isFavorite) {
			const { trackEvent } = require('../services/analyticsService');
			trackEvent({
				eventType: 'university_favourite',
				universityId,
				studentId: student._id,
				userId: req.user.userId,
			}).catch((err) => console.error('Failed to track favourite event:', err.message));
		}

		return res.json({
			success: true,
			message: isFavorite ? 'Added to favorites' : 'Removed from favorites',
			isFavorite,
			favoriteUniversities: student.favoriteUniversities,
		});
	} catch (error) { return next(error); }
}

module.exports = {
	createStudent,
	getStudent,
	getMyStudent,
	updateStudent,
	deleteStudent,
	getFavoriteUniversities,
	toggleFavoriteUniversity,
};
