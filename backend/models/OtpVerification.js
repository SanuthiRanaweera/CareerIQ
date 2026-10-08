const mongoose = require('mongoose');

const otpVerificationSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    otpHash: { type: String, required: true },
    purpose: { type: String, required: true, enum: ['university_login', 'university_activation', 'university_registration', 'password_reset'], index: true },
    expiresAt: { type: Date, required: true, index: true },
    attempts: { type: Number, default: 0 },
    verified: { type: Boolean, default: false },
    lastSentAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

otpVerificationSchema.index({ userId: 1, purpose: 1, createdAt: -1 });

module.exports = mongoose.model('OtpVerification', otpVerificationSchema);
