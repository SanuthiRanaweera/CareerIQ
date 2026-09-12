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

module.exports = { createStudent, getStudent, getMyStudent, updateStudent, deleteStudent };
