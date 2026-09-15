const jwt = require('jsonwebtoken');
const User = require('../models/User');

async function protect(req, res, next) {
	try {
		const header = req.headers.authorization;
		if (!header?.startsWith('Bearer ')) return res.status(401).json({ success: false, message: 'Authentication required' });
		const payload = jwt.verify(header.slice(7), process.env.JWT_SECRET);
		const user = await User.findById(payload.userId);
		if (!user) return res.status(401).json({ success: false, message: 'User account not found' });
		req.user = { userId: user._id, email: user.email, role: user.role };
		return next();
	} catch (_error) { return res.status(401).json({ success: false, message: 'Invalid or expired token' }); }
}

module.exports = { protect };
