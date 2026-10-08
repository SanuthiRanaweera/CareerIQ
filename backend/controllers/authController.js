const authService = require('../services/authService');

function validateCredentials(body, registration = false) {
	if (!body.email || !/^\S+@\S+\.\S+$/.test(body.email)) throw Object.assign(new Error('A valid email is required'), { statusCode: 400 });
	if (!body.password || body.password.length < 6) throw Object.assign(new Error('Password must contain at least 6 characters'), { statusCode: 400 });
	if (registration && (!body.fullName || body.fullName.trim().length < 2)) throw Object.assign(new Error('Full name is required'), { statusCode: 400 });
	if (registration && body.password !== body.confirmPassword) throw Object.assign(new Error('Passwords do not match'), { statusCode: 400 });
}

async function register(req, res, next) {
	try { validateCredentials(req.body, true); res.status(201).json({ success: true, message: 'Student account created successfully', data: await authService.register(req.body) }); }
	catch (error) { next(error); }
}

async function login(req, res, next) {
	try {
		validateCredentials(req.body);
		const data = await authService.login(req.body);
		const message = data.pendingUniversityOtp ? 'University verification code sent' : 'Login successful';
		res.json({ success: true, message, data });
	} catch (error) { next(error); }
}

async function googleLogin(req, res, next) {
	try {
		if (!req.body.idToken || typeof req.body.idToken !== 'string') throw Object.assign(new Error('Google sign-in token is required'), { statusCode: 400 });
		res.json({ success: true, message: 'Google login successful', data: await authService.googleLogin(req.body.idToken) });
	} catch (error) { next(error); }
}

async function verifyEmail(req, res, next) {
	try {
		if (!req.body.email || !/^\d{6}$/.test(req.body.otp)) throw Object.assign(new Error('Email and six-digit OTP are required'), { statusCode: 400 });
		await authService.verifyEmail(req.body.email, req.body.otp);
		res.json({ success: true, message: 'Email verified successfully' });
	} catch (error) { next(error); }
}

async function resendVerificationEmail(req, res, next) {
	try {
		if (!req.body.email || !/^\S+@\S+\.\S+$/.test(req.body.email)) throw Object.assign(new Error('A valid email is required'), { statusCode: 400 });
		await authService.resendVerificationEmail(req.body.email);
		res.json({ success: true, message: 'A new verification code has been sent' });
	} catch (error) { next(error); }
}

async function verifyUniversityOtp(req, res, next) {
	try {
		if (!req.body.email || !/^\S+@\S+\.\S+$/.test(req.body.email)) throw Object.assign(new Error('A valid university email is required'), { statusCode: 400 });
		if (!req.body.otp || !/^\d{6}$/.test(String(req.body.otp))) throw Object.assign(new Error('A six-digit OTP is required'), { statusCode: 400 });
		const data = await authService.verifyUniversityOtp(req.body.email, req.body.otp);
		res.json({ success: true, message: 'University login verified successfully', data });
	} catch (error) { next(error); }
}

async function resendUniversityOtp(req, res, next) {
	try {
		if (!req.body.email || !/^\S+@\S+\.\S+$/.test(req.body.email)) throw Object.assign(new Error('A valid university email is required'), { statusCode: 400 });
		const result = await authService.resendUniversityOtp(req.body.email);
		res.json({ success: true, message: 'A new verification code has been sent', data: result });
	} catch (error) { next(error); }
}

module.exports = { register, login, googleLogin, verifyEmail, resendVerificationEmail, verifyUniversityOtp, resendUniversityOtp };
