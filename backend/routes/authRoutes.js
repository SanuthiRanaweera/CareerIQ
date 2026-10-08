const express = require('express');
const {
	register,
	login,
	googleLogin,
	verifyEmail,
	resendVerificationEmail,
	verifyUniversityOtp,
	resendUniversityOtp,
} = require('../controllers/authController');

const router = express.Router();
router.post('/register', register);
router.post('/login', login);
router.post('/university/login', login);
router.post('/google', googleLogin);
router.post('/verify-email', verifyEmail);
router.post('/resend-verification', resendVerificationEmail);
router.post('/university/verify-otp', verifyUniversityOtp);
router.post('/university/resend-otp', resendUniversityOtp);

module.exports = router;
