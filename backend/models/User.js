const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
	{
		fullName: { type: String, required: true, trim: true, maxlength: 100 },
		email: { type: String, required: true, unique: true, lowercase: true, trim: true },
		password: { type: String, required: true, minlength: 6, select: false },
		role: { type: String, enum: ['student'], default: 'student' },
		isEmailVerified: { type: Boolean, default: false },
		emailVerificationOtpHash: { type: String, select: false },
		emailVerificationOtpExpiresAt: { type: Date, select: false },
	},
	{ timestamps: true },
);

module.exports = mongoose.model('User', userSchema);
