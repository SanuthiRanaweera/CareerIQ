const bcrypt = require('bcrypt');
const crypto = require('node:crypto');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Student = require('../models/Student');
const { sendVerificationEmail } = require('./emailService');

function createToken(user) {
	const secret = process.env.JWT_SECRET;
	if (!secret) throw new Error('JWT_SECRET is not configured in the environment');
	return jwt.sign({ userId: user._id.toString(), role: user.role }, secret, { expiresIn: '7d' });
}

function publicUser(user) {
	return { id: user._id, fullName: user.fullName, email: user.email, role: user.role, isEmailVerified: user.isEmailVerified };
}

async function register({ fullName, email, password, dateOfBirth, school, district, alYear }) {
	const normalizedEmail = email.toLowerCase().trim();
	if (await User.exists({ email: normalizedEmail })) {
		const error = new Error('An account with this email already exists');
		error.statusCode = 409;
		throw error;
	}
	const verificationOtp = String(crypto.randomInt(100000, 1000000));
	const user = await User.create({
		fullName, email: normalizedEmail, password: await bcrypt.hash(password, 12),
		emailVerificationOtpHash: crypto.createHash('sha256').update(verificationOtp).digest('hex'),
		emailVerificationOtpExpiresAt: new Date(Date.now() + 10 * 60 * 1000),
	});
	const student = await Student.create({ userId: user._id, fullName, email: normalizedEmail, dateOfBirth, school, district, alYear });
	await sendVerificationEmail({ email: normalizedEmail, fullName, otp: verificationOtp });
	return { user: publicUser(user), student };
}

async function login({ email, password }) {
	const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');
	if (!user || !(await bcrypt.compare(password, user.password))) {
		const error = new Error('Invalid email or password');
		error.statusCode = 401;
		throw error;
	}
	if (!user.isEmailVerified) {
		const error = new Error('Please verify your email before logging in');
		error.statusCode = 403;
		throw error;
	}
	const student = await Student.findOne({ userId: user._id });
	return { token: createToken(user), user: publicUser(user), student };
}

async function verifyEmail(email, otp) {
	const otpHash = crypto.createHash('sha256').update(String(otp)).digest('hex');
	const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+emailVerificationOtpHash +emailVerificationOtpExpiresAt');
	if (!user || user.emailVerificationOtpHash !== otpHash || !user.emailVerificationOtpExpiresAt || user.emailVerificationOtpExpiresAt < new Date()) {
		const error = new Error('Invalid or expired verification code');
		error.statusCode = 400;
		throw error;
	}
	user.isEmailVerified = true;
	user.emailVerificationOtpHash = undefined;
	user.emailVerificationOtpExpiresAt = undefined;
	await user.save();
	return user;
}

module.exports = { register, login, verifyEmail };
