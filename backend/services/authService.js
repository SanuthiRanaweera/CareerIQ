const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Student = require('../models/Student');

function createToken(user) {
	const secret = process.env.JWT_SECRET;
	if (!secret) throw new Error('JWT_SECRET is not configured in the environment');
	return jwt.sign({ userId: user._id.toString(), role: user.role }, secret, { expiresIn: '7d' });
}

function publicUser(user) {
	return { id: user._id, fullName: user.fullName, email: user.email, role: user.role };
}

async function register({ fullName, email, password, dateOfBirth, school, district, alYear }) {
	const normalizedEmail = email.toLowerCase().trim();
	if (await User.exists({ email: normalizedEmail })) {
		const error = new Error('An account with this email already exists');
		error.statusCode = 409;
		throw error;
	}
	const user = await User.create({ fullName, email: normalizedEmail, password: await bcrypt.hash(password, 12) });
	const student = await Student.create({ userId: user._id, fullName, email: normalizedEmail, dateOfBirth, school, district, alYear });
	return { token: createToken(user), user: publicUser(user), student };
}

async function login({ email, password }) {
	const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');
	if (!user || !(await bcrypt.compare(password, user.password))) {
		const error = new Error('Invalid email or password');
		error.statusCode = 401;
		throw error;
	}
	const student = await Student.findOne({ userId: user._id });
	return { token: createToken(user), user: publicUser(user), student };
}

module.exports = { register, login };
