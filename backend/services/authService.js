const bcrypt = require('bcrypt');
const crypto = require('node:crypto');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
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

async function googleLogin(idToken) {
	const clientId = process.env.GOOGLE_CLIENT_ID;
	if (!clientId) throw Object.assign(new Error('GOOGLE_CLIENT_ID is not configured in backend/.env'), { statusCode: 503 });
	const ticket = await new OAuth2Client().verifyIdToken({ idToken, audience: clientId });
	const payload = ticket.getPayload();
	if (!payload?.sub || !payload.email || payload.email_verified !== true) {
		throw Object.assign(new Error('Google account email could not be verified'), { statusCode: 401 });
	}
	const email = payload.email.toLowerCase().trim();
	let user = await User.findOne({ $or: [{ googleId: payload.sub }, { email }] }).select('+googleId');
	if (user?.googleId && user.googleId !== payload.sub) throw Object.assign(new Error('This email is linked to a different Google account'), { statusCode: 409 });
	if (!user) {
		user = await User.create({ fullName: payload.name || email.split('@')[0], email, googleId: payload.sub, authProvider: 'google', isEmailVerified: true });
		await Student.create({ userId: user._id, fullName: user.fullName, email });
	} else if (!user.googleId) {
		user.googleId = payload.sub;
		user.authProvider = 'google';
		user.isEmailVerified = true;
		await user.save();
	}
	const student = await Student.findOne({ userId: user._id });
	return { token: createToken(user), user: publicUser(user), student };
}

async function register({ fullName, email, password, dateOfBirth, school, district, alYear }) {
	const normalizedEmail = email.toLowerCase().trim();
	const existingUser = await User.findOne({ email: normalizedEmail });
	if (existingUser?.isEmailVerified) {
		const error = new Error('An account with this email already exists');
		error.statusCode = 409;
		throw error;
	}
	if (existingUser) {
		const student = await Student.findOne({ userId: existingUser._id });
		await resendVerificationEmail(normalizedEmail);
		return { user: publicUser(existingUser), student };
	}
	const verificationOtp = String(crypto.randomInt(100000, 1000000));
	const user = await User.create({
		fullName, email: normalizedEmail, password: await bcrypt.hash(password, 12),
		emailVerificationOtpHash: crypto.createHash('sha256').update(verificationOtp).digest('hex'),
		emailVerificationOtpExpiresAt: new Date(Date.now() + 10 * 60 * 1000),
	});
	let student;
	try {
		student = await Student.create({ userId: user._id, fullName, email: normalizedEmail, dateOfBirth, school, district, alYear });
		await sendVerificationEmail({ email: normalizedEmail, fullName, otp: verificationOtp });
	} catch (error) {
		await Student.deleteOne({ userId: user._id });
		await User.deleteOne({ _id: user._id });
		const emailError = new Error(`Account was not created because the verification email could not be sent: ${error.message}`);
		emailError.statusCode = 503;
		throw emailError;
	}
	return { user: publicUser(user), student };
}

async function resendVerificationEmail(email) {
	const normalizedEmail = email.toLowerCase().trim();
	const user = await User.findOne({ email: normalizedEmail }).select('+emailVerificationOtpHash +emailVerificationOtpExpiresAt');
	if (!user) {
		const error = new Error('No account was found for this email');
		error.statusCode = 404;
		throw error;
	}
	if (user.isEmailVerified) {
		const error = new Error('This email is already verified. You can log in.');
		error.statusCode = 409;
		throw error;
	}
	const verificationOtp = String(crypto.randomInt(100000, 1000000));
	user.emailVerificationOtpHash = crypto.createHash('sha256').update(verificationOtp).digest('hex');
	user.emailVerificationOtpExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
	await user.save();
	try {
		await sendVerificationEmail({ email: normalizedEmail, fullName: user.fullName, otp: verificationOtp });
	} catch (error) {
		const emailError = new Error(`The verification email could not be sent: ${error.message}`);
		emailError.statusCode = 503;
		throw emailError;
	}
}

async function login({ email, password }) {
	const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');
	if (!user || !user.password || !(await bcrypt.compare(password, user.password))) {
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

module.exports = { register, login, googleLogin, verifyEmail, resendVerificationEmail };
