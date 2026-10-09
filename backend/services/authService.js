const bcrypt = require('bcrypt');
const crypto = require('node:crypto');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const Student = require('../models/Student');
const University = require('../models/University');
const OtpVerification = require('../models/OtpVerification');
const { sendVerificationEmail, sendUniversityOtpEmail, sendUniversityAccountCreatedEmail } = require('./emailService');
const { createOtpRecord, verifyOtp, canResendOtp, OTP_COOLDOWN_MS } = require('./otpService');

function createToken(user) {
	const secret = process.env.JWT_SECRET;
	if (!secret) throw new Error('JWT_SECRET is not configured in the environment');
	return jwt.sign({ userId: user._id.toString(), role: user.role }, secret, { expiresIn: '7d' });
}

function publicUser(user) {
	return { id: user._id, fullName: user.fullName, email: user.email, role: user.role, status: user.status, isEmailVerified: user.isEmailVerified };
}

function generateTemporaryPassword() {
	const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
	const lower = 'abcdefghijkmnopqrstuvwxyz';
	const numbers = '23456789';
	const specials = '!@#$%^&*';
	const pool = `${upper}${lower}${numbers}${specials}`;
	let password = [
		upper[Math.floor(Math.random() * upper.length)],
		lower[Math.floor(Math.random() * lower.length)],
		numbers[Math.floor(Math.random() * numbers.length)],
		specials[Math.floor(Math.random() * specials.length)],
	];
	for (let i = 4; i < 12; i += 1) {
		password.push(pool[Math.floor(Math.random() * pool.length)]);
	}
	return password.sort(() => Math.random() - 0.5).join('');
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
		await Student.create({ userId: user._id, fullName: user.fullName, email, profileImage: payload.picture });
	} else if (!user.googleId) {
		user.googleId = payload.sub;
		user.authProvider = 'google';
		user.isEmailVerified = true;
		await user.save();
	}
	let student = await Student.findOne({ userId: user._id });
	if (student && !student.profileImage && payload.picture) {
		student.profileImage = payload.picture;
		await student.save();
	}
	return { token: createToken(user), user: publicUser(user), student };
}

async function register({ fullName, email, password, dateOfBirth, school, district, alYear, profileImage }) {
	const normalizedEmail = email.toLowerCase().trim();
	const existingUser = await User.findOne({ email: normalizedEmail });
	if (existingUser?.isEmailVerified) {
		const error = new Error('An account with this email already exists');
		error.statusCode = 409;
		throw error;
	}
	if (existingUser) {
		let student = await Student.findOne({ userId: existingUser._id });
		if (student && profileImage) {
			student.profileImage = typeof profileImage === 'string' ? profileImage.trim() : student.profileImage;
			await student.save();
		}
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
		student = await Student.create({
			userId: user._id,
			fullName,
			email: normalizedEmail,
			dateOfBirth,
			school,
			district,
			alYear,
			profileImage: typeof profileImage === 'string' && profileImage.trim() ? profileImage.trim() : undefined,
		});
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
	const normalizedEmail = String(email).toLowerCase().trim();
	const user = await User.findOne({ email: normalizedEmail }).select('+password');
	if (!user || !user.password || !(await bcrypt.compare(password, user.password))) {
		const error = new Error('Invalid email or password');
		error.statusCode = 401;
		throw error;
	}

	if (user.role === 'university') {
		if (user.status === 'inactive') {
			const error = new Error('Your university account is inactive. Please contact the administrator.');
			error.statusCode = 403;
			throw error;
		}
		if (user.status === 'pending') {
			const error = new Error('Your university account is pending activation. Please contact the administrator.');
			error.statusCode = 403;
			throw error;
		}
		const university = await University.findOne({ userId: user._id });
		const { allowed, retryAfterSeconds } = await canResendOtp({ userId: user._id, purpose: 'university_login' });
		if (!allowed) {
			const error = new Error(`Please wait ${retryAfterSeconds} seconds before requesting a new code.`);
			error.statusCode = 429;
			throw error;
		}
		const { otp, record } = await createOtpRecord({ userId: user._id, purpose: 'university_login' });
		await OtpVerification.deleteMany({ userId: user._id, purpose: 'university_login', _id: { $ne: record._id } });
		try {
			await sendUniversityOtpEmail({
				universityName: university?.universityName || user.fullName,
				email: normalizedEmail,
				otp,
			});
		} catch (error) {
			throw Object.assign(new Error('Unable to send verification email. Please try again.'), { statusCode: 503, cause: error });
		}
		return {
			pendingUniversityOtp: true,
			token: null,
			message: 'Verification code sent to your university email.',
			user: publicUser(user),
			retryAfterSeconds: Math.max(0, Math.ceil(OTP_COOLDOWN_MS / 1000)),
		};
	}

	if (!user.isEmailVerified) {
		const error = new Error('Please verify your email before logging in');
		error.statusCode = 403;
		throw error;
	}
	const student = await Student.findOne({ userId: user._id });
	return { token: createToken(user), user: publicUser(user), student };
}

async function verifyUniversityOtp(email, otp) {
	const normalizedEmail = String(email).toLowerCase().trim();
	const user = await User.findOne({ email: normalizedEmail }).select('+password');
	if (!user || user.role !== 'university') {
		const error = new Error('University account not found');
		error.statusCode = 404;
		throw error;
	}
	if (user.status === 'inactive') {
		const error = new Error('Your university account is inactive. Please contact the administrator.');
		error.statusCode = 403;
		throw error;
	}
	if (user.status === 'pending') {
		const error = new Error('Your university account is pending activation. Please contact the administrator.');
		error.statusCode = 403;
		throw error;
	}
	await verifyOtp({ userId: user._id, purpose: 'university_login', otp });
	const university = await University.findOne({ userId: user._id });
	return { token: createToken(user), user: publicUser(user), university };
}

async function resendUniversityOtp(email) {
	const normalizedEmail = String(email).toLowerCase().trim();
	const user = await User.findOne({ email: normalizedEmail }).select('+password');
	if (!user || user.role !== 'university') {
		const error = new Error('University account not found');
		error.statusCode = 404;
		throw error;
	}
	const { allowed, retryAfterSeconds } = await canResendOtp({ userId: user._id, purpose: 'university_login' });
	if (!allowed) {
		const error = new Error(`Please wait ${retryAfterSeconds} seconds before requesting a new code.`);
		error.statusCode = 429;
		throw error;
	}
	const university = await University.findOne({ userId: user._id });
	const { otp } = await createOtpRecord({ userId: user._id, purpose: 'university_login' });
	try {
		await sendUniversityOtpEmail({ universityName: university?.universityName || user.fullName, email: normalizedEmail, otp });
	} catch (error) {
		throw Object.assign(new Error('Unable to send verification email. Please try again.'), { statusCode: 503, cause: error });
	}
	return { retryAfterSeconds: Math.max(0, Math.ceil(OTP_COOLDOWN_MS / 1000)) };
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

async function createUniversityAccount({ universityName, officialEmail, contactNumber, address, city, district, country, universityType, website, description, logo, status = 'pending', password }) {
	const normalizedEmail = String(officialEmail).toLowerCase().trim();
	const existing = await User.findOne({ email: normalizedEmail });
	if (existing) {
		const error = new Error('A university account with this email already exists');
		error.statusCode = 409;
		throw error;
	}
	const tempPassword = password || generateTemporaryPassword();
	const user = await User.create({
		fullName: universityName,
		email: normalizedEmail,
		password: await bcrypt.hash(tempPassword, 12),
		role: 'university',
		status,
		isEmailVerified: true,
		mustResetPassword: Boolean(password === undefined || password === null),
	});
	try {
		const university = await University.create({
			userId: user._id,
			universityName,
			officialEmail: normalizedEmail,
			contactNumber,
			address,
			city,
			district,
			country,
			universityType,
			website,
			description,
			logo,
			status,
		});
		await sendUniversityAccountCreatedEmail({ email: normalizedEmail, universityName, password: tempPassword });
		return { user: publicUser(user), university };
	} catch (error) {
		await User.deleteOne({ _id: user._id });
		throw error;
	}
}

module.exports = {
	register,
	login,
	googleLogin,
	verifyEmail,
	resendVerificationEmail,
	verifyUniversityOtp,
	resendUniversityOtp,
	createUniversityAccount,
};
