const Student = require('../models/Student');

async function getOwnedStudent(userId, studentId) {
	const student = await Student.findOne({ _id: studentId, userId });
	if (!student) {
		const error = new Error('Student profile not found');
		error.statusCode = 404;
		throw error;
	}
	return student;
}

async function updateOwnedStudent(userId, studentId, updates) {
	const allowed = ['fullName', 'dateOfBirth', 'school', 'district', 'alYear', 'stream', 'profileImage', 'interests', 'alResults', 'personalityResult'];
	const safeUpdates = Object.fromEntries(Object.entries(updates).filter(([key]) => allowed.includes(key)));
	return Student.findOneAndUpdate({ _id: studentId, userId }, safeUpdates, { new: true, runValidators: true });
}

module.exports = { getOwnedStudent, updateOwnedStudent };
