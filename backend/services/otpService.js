const crypto = require('node:crypto');
const OtpVerification = require('../models/OtpVerification');

const OTP_LENGTH = 6;
const OTP_TTL_MS = 5 * 60 * 1000;
const OTP_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function hashOtp(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

async function createOtpRecord({ userId, purpose, overrideExpiryMs = OTP_TTL_MS }) {
  const otp = generateOtp();
  const otpHash = hashOtp(otp);
  const expiresAt = new Date(Date.now() + overrideExpiryMs);

  const record = await OtpVerification.create({
    userId,
    otpHash,
    purpose,
    expiresAt,
    attempts: 0,
    verified: false,
    lastSentAt: new Date(),
  });

  return { otp, record };
}

async function getActiveOtpRecord({ userId, purpose, requireLatest = true }) {
  const query = { userId, purpose, verified: false };
  const cursor = OtpVerification.find(query).sort({ createdAt: -1 });
  const record = requireLatest ? await cursor.limit(1).lean().exec().then((items) => items[0] ?? null) : await cursor.lean().exec().then((items) => items[0] ?? null);
  return record ? { ...record, _id: record._id?.toString?.() || record._id } : null;
}

async function verifyOtp({ userId, purpose, otp }) {
  const record = await OtpVerification.findOne({ userId, purpose, verified: false }).sort({ createdAt: -1 });
  if (!record) {
    throw Object.assign(new Error('Invalid verification code.'), { statusCode: 400 });
  }

  if (record.expiresAt < new Date()) {
    record.verified = true;
    await record.save();
    throw Object.assign(new Error('Verification code has expired. Please request a new code.'), { statusCode: 400 });
  }

  const otpHash = hashOtp(otp);
  if (record.otpHash !== otpHash) {
    record.attempts = Number(record.attempts || 0) + 1;
    if (record.attempts >= MAX_ATTEMPTS) {
      record.verified = true;
      await record.save();
      throw Object.assign(new Error('Too many attempts. Please request a new code.'), { statusCode: 429 });
    }
    await record.save();
    throw Object.assign(new Error('Invalid verification code.'), { statusCode: 400 });
  }

  record.verified = true;
  await record.save();
  await OtpVerification.deleteMany({ userId, purpose, verified: true });
  return true;
}

async function canResendOtp({ userId, purpose }) {
  const latest = await OtpVerification.findOne({ userId, purpose }).sort({ createdAt: -1 });
  if (!latest) return { allowed: true, retryAfterSeconds: 0 };
  const elapsed = Date.now() - new Date(latest.lastSentAt || latest.createdAt).getTime();
  const retryAfterSeconds = Math.max(0, Math.ceil((OTP_COOLDOWN_MS - elapsed) / 1000));
  return { allowed: retryAfterSeconds <= 0, retryAfterSeconds };
}

module.exports = {
  OTP_LENGTH,
  OTP_TTL_MS,
  OTP_COOLDOWN_MS,
  MAX_ATTEMPTS,
  generateOtp,
  hashOtp,
  createOtpRecord,
  getActiveOtpRecord,
  verifyOtp,
  canResendOtp,
};
