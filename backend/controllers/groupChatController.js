const GroupMessage = require('../models/GroupMessage');
const Student = require('../models/Student');
const User = require('../models/User');

async function listMessages(req, res, next) {
	try {
		const limit = Math.min(100, Math.max(1, Number.parseInt(req.query.limit, 10) || 60));
		const messages = await GroupMessage.find()
			.sort({ createdAt: -1 })
			.limit(limit)
			.lean();
		return res.json({ success: true, data: messages.reverse() });
	} catch (error) { return next(error); }
}

async function sendMessage(req, res, next) {
	try {
		const message = typeof req.body.message === 'string' ? req.body.message.trim() : '';
		if (!message) return res.status(400).json({ success: false, message: 'Message cannot be empty' });
		if (message.length > 1000) return res.status(400).json({ success: false, message: 'Message must be 1000 characters or fewer' });
		const [user, student] = await Promise.all([
			User.findById(req.user.userId).select('fullName'),
			Student.findOne({ userId: req.user.userId }).select('_id profileImage'),
		]);
		if (!user) return res.status(401).json({ success: false, message: 'User account not found' });
		if (!student) return res.status(404).json({ success: false, message: 'Student profile not found' });
		const saved = await GroupMessage.create({
			senderId: user._id,
			senderStudentId: student._id,
			senderName: user.fullName,
			senderProfileImage: student.profileImage || '',
			message,
		});
		return res.status(201).json({ success: true, data: saved });
	} catch (error) { return next(error); }
}

module.exports = { listMessages, sendMessage };