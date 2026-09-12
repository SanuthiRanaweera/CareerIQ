function errorHandler(error, _req, res, _next) {
	console.error(error);
	const status = error.statusCode || (error.name === 'ValidationError' ? 400 : 500);
	res.status(status).json({ success: false, message: status === 500 ? 'Server error' : error.message });
}

module.exports = errorHandler;
