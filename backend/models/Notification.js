const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
	{
		recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
		sentBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
		title: { type: String, required: true, trim: true, maxlength: 100 },
		message: { type: String, required: true, trim: true, maxlength: 2000 },
		readAt: { type: Date, default: null },
	},
	{ timestamps: true },
);

notificationSchema.index({ recipient: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);