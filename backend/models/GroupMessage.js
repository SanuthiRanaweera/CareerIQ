const mongoose = require('mongoose');

const groupMessageSchema = new mongoose.Schema(
	{
		senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
		senderStudentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
		senderName: { type: String, required: true, trim: true, maxlength: 100 },
		senderProfileImage: { type: String, trim: true, default: '' },
		message: { type: String, required: true, trim: true, maxlength: 1000 },
	},
	{ timestamps: true },
);

groupMessageSchema.index({ createdAt: -1 });

module.exports = mongoose.model('GroupMessage', groupMessageSchema);