const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
	{
		fullName: { type: String, required: true, trim: true, maxlength: 100 },
		email: { type: String, required: true, unique: true, lowercase: true, trim: true },
		password: { type: String, minlength: 6, select: false },
		googleId: { type: String, unique: true, sparse: true, select: false },
		authProvider: { type: String, enum: ['password', 'google'], default: 'password' },
		role: { type: String, enum: ['student'], default: 'student' },
		isEmailVerified: { type: Boolean, default: false },
		emailVerificationOtpHash: { type: String, select: false },
		emailVerificationOtpExpiresAt: { type: Date, select: false },
	},
	{ timestamps: true },
);

module.exports = mongoose.model('User', userSchema);
