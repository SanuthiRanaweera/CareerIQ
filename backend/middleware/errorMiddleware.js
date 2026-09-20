function errorHandler(error, _req, res, _next) {
	console.error(error);
	const status = error.statusCode || (error.name === 'ValidationError' ? 400 : 500);
	const message = error.expose || status < 500 ? error.message : 'Server error';
	res.status(status).json({ success: false, message });
}

module.exports = errorHandler;
