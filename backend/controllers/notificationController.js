const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const Student = require('../models/Student');
const User = require('../models/User');

function adminOnly(req, res, next) {
	if (req.user?.role !== 'admin') {
		return res.status(403).json({ success: false, message: 'Administrator access required' });
	}
	return next();
}

async function listRecipients(req, res, next) {
	try {
		const search = String(req.query.search || '').trim();
		const studentUsers = await User.find({ role: 'student' }).select('_id').lean();
		const filter = {};
		filter.userId = { $in: studentUsers.map((user) => user._id) };
		if (search) {
			const escaped = search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
			const expression = new RegExp(escaped, 'i');
			filter.$or = [{ fullName: expression }, { email: expression }, { school: expression }];
		}
		const students = await Student.find(filter)
			.select('_id fullName email school district')
			.sort({ fullName: 1 })
			.limit(500)
			.lean();
		return res.json({ success: true, data: students });
	} catch (error) { return next(error); }
}

async function sendNotification(req, res, next) {
	try {
		if (req.user.role !== 'admin') {
			return res.status(403).json({ success: false, message: 'Administrator access required' });
		}
		const title = typeof req.body.title === 'string' ? req.body.title.trim() : '';
		const message = typeof req.body.message === 'string' ? req.body.message.trim() : '';
		const recipientType = req.body.recipientType;
		if (!title || title.length > 100) {
			return res.status(400).json({ success: false, message: 'Title is required (maximum 100 characters)' });
		}
		if (!message || message.length > 2000) {
			return res.status(400).json({ success: false, message: 'Message is required (maximum 2000 characters)' });
		}
		if (!['all', 'selected'].includes(recipientType)) {
			return res.status(400).json({ success: false, message: 'Choose all students or selected students' });
		}

		let recipients;
		const studentUsers = await User.find({ role: 'student' }).select('_id').lean();
		const studentUserIds = studentUsers.map((user) => user._id);
		if (recipientType === 'all') {
			recipients = await Student.find({ userId: { $in: studentUserIds } }).select('_id').lean();
		} else {
			const studentIds = Array.isArray(req.body.studentIds) ? [...new Set(req.body.studentIds)] : [];
			if (studentIds.length === 0 || studentIds.some((id) => !mongoose.isValidObjectId(id))) {
				return res.status(400).json({ success: false, message: 'Select at least one valid student' });
			}
			recipients = await Student.find({
				_id: { $in: studentIds },
				userId: { $in: studentUserIds },
			}).select('_id').lean();
		}
		if (recipients.length === 0) {
			return res.status(404).json({ success: false, message: 'No students are available to receive this notification' });
		}

		await Notification.insertMany(recipients.map(({ _id }) => ({
			recipient: _id,
			sentBy: req.user.userId,
			title,
			message,
		})));
		return res.status(201).json({ success: true, message: 'Notification sent', recipientCount: recipients.length });
	} catch (error) { return next(error); }
}

async function listMyNotifications(req, res, next) {
	try {
		const student = await Student.findOne({ userId: req.user.userId }).select('_id');
		if (!student) return res.status(404).json({ success: false, message: 'Student profile not found' });
		const notifications = await Notification.find({ recipient: student._id })
			.sort({ createdAt: -1 })
			.limit(100)
			.lean();
		const unreadCount = notifications.filter((item) => !item.readAt).length;
		return res.json({ success: true, data: notifications, unreadCount });
	} catch (error) { return next(error); }
}

async function markAsRead(req, res, next) {
	try {
		const student = await Student.findOne({ userId: req.user.userId }).select('_id');
		if (!student) return res.status(404).json({ success: false, message: 'Student profile not found' });
		if (!mongoose.isValidObjectId(req.params.id)) {
			return res.status(404).json({ success: false, message: 'Notification not found' });
		}
		const notification = await Notification.findOneAndUpdate(
			{ _id: req.params.id, recipient: student._id },
			{ $set: { readAt: new Date() } },
			{ new: true },
		).lean();
		if (!notification) return res.status(404).json({ success: false, message: 'Notification not found' });
		return res.json({ success: true, data: notification });
	} catch (error) { return next(error); }
}

module.exports = { adminOnly, listRecipients, sendNotification, listMyNotifications, markAsRead };