function adminOnly(req, res, next) {
  if (req.user?.role !== 'admin') {
    return res.status(403).json({ success: false, message: 'Administrator access required' });
  }
  return next();
}

module.exports = { adminOnly };
