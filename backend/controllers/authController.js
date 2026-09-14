const authService = require('../services/authService');

function validateCredentials(body, registration = false) {
	if (!body.fullName && registration) throw Object.assign(new Error('Full name is required'), { statusCode: 400 });
	if (!body.email || !/^\S+@\S+\.\S+$/.test(body.email)) throw Object.assign(new Error('A valid email is required'), { statusCode: 400 });
	if (!body.password || body.password.length < 6) throw Object.assign(new Error('Password must contain at least 6 characters'), { statusCode: 400 });
	if (registration && body.password !== body.confirmPassword) throw Object.assign(new Error('Passwords do not match'), { statusCode: 400 });
}

async function register(req, res, next) {
	try { validateCredentials(req.body, true); res.status(201).json({ success: true, message: 'Student account created successfully', data: await authService.register(req.body) }); }
	catch (error) { next(error); }
}

async function login(req, res, next) {
	try { validateCredentials(req.body); res.json({ success: true, message: 'Login successful', data: await authService.login(req.body) }); }
	catch (error) { next(error); }
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

module.exports = { register, login, verifyEmail, resendVerificationEmail };
