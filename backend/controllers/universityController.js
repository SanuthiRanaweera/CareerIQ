const bcrypt = require('bcrypt');
const User = require('../models/User');
const University = require('../models/University');
const Course = require('../models/Course');
const OtpVerification = require('../models/OtpVerification');
const { createOtpRecord, verifyOtp, canResendOtp } = require('../services/otpService');
const { sendUniversityRegistrationOtpEmail } = require('../services/emailService');

function validateEmail(email) {
  return /^\S+@\S+\.\S+$/.test(email);
}

function escapeRegex(text) {
  return String(text).replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
}

function calculateProfileCompletion(university) {
  const fields = [
    university.universityName,
    university.officialEmail,
    university.location,
    university.address,
    university.contactNumber,
    university.representativeName,
    university.representativeEmail,
    university.representativeContactNumber,
    university.website,
    university.description,
    university.logo,
  ];
  const completed = fields.filter(
    (val) => val && typeof val === 'string' && val.trim().length > 0
  ).length;
  const total = fields.length;
  const percentage = Math.round((completed / total) * 100);
  return { percentage, completed, total };
}

// 1. CREATE UNIVERSITY (Admin-only)
async function createUniversity(req, res, next) {
  try {
    const {
      universityName,
      location,
      officialEmail,
      address,
      contactNumber,
      representativeName,
      representativeEmail,
      representativeContactNumber,
      password,
      confirmPassword,
      status: requestedStatus,
      universityType,
    } = req.body;

    // Required fields validation
    if (!universityName || !String(universityName).trim()) {
      return res.status(400).json({ success: false, message: 'University Name is required.' });
    }
    if (!location || !String(location).trim()) {
      return res.status(400).json({ success: false, message: 'University Location is required.' });
    }
    if (!officialEmail || !validateEmail(String(officialEmail).trim())) {
      return res.status(400).json({ success: false, message: 'A valid University Official Email is required.' });
    }
    if (!address || !String(address).trim()) {
      return res.status(400).json({ success: false, message: 'University Address is required.' });
    }
    if (!contactNumber || !String(contactNumber).trim()) {
      return res.status(400).json({ success: false, message: 'University Contact Number is required.' });
    }
    if (!representativeName || !String(representativeName).trim()) {
      return res.status(400).json({ success: false, message: 'Admin/Representative Name is required.' });
    }
    if (!representativeContactNumber || !String(representativeContactNumber).trim()) {
      return res.status(400).json({ success: false, message: 'Admin/Representative Contact Number is required.' });
    }
    if (!password || String(password).length < 6) {
      return res.status(400).json({ success: false, message: 'Password must contain at least 6 characters.' });
    }
    if (password !== confirmPassword) {
      return res.status(400).json({ success: false, message: 'Passwords do not match.' });
    }

    const normalizedOfficialEmail = String(officialEmail).toLowerCase().trim();

    // Duplicate email validation
    const existingUser = await User.findOne({ email: normalizedOfficialEmail });
    const existingUni = await University.findOne({ officialEmail: normalizedOfficialEmail });
    if (existingUser || existingUni) {
      return res.status(409).json({
        success: false,
        message: 'An account already exists with this email.',
      });
    }

    // Determine initial status (active / inactive after verification)
    const initialStatus = requestedStatus === 'inactive' ? 'inactive' : 'active';

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create User record
    const user = await User.create({
      fullName: String(representativeName).trim(),
      email: normalizedOfficialEmail,
      password: hashedPassword,
      role: 'university',
      status: 'pending',
      isEmailVerified: false,
    });

    // Create University record
    let university;
    try {
      university = await University.create({
        userId: user._id,
        universityName: String(universityName).trim(),
        location: String(location).trim(),
        officialEmail: normalizedOfficialEmail,
        address: String(address).trim(),
        contactNumber: String(contactNumber).trim(),
        representativeName: String(representativeName).trim(),
        representativeEmail: representativeEmail ? String(representativeEmail).toLowerCase().trim() : '',
        representativeContactNumber: String(representativeContactNumber).trim(),
        universityType: universityType ? String(universityType).trim() : 'State University',
        status: 'pending_verification',
      });
    } catch (err) {
      await User.deleteOne({ _id: user._id });
      throw err;
    }

    // Generate secure 6-digit OTP
    const { otp } = await createOtpRecord({
      userId: user._id,
      purpose: 'university_registration',
      overrideExpiryMs: 5 * 60 * 1000, // 5 minutes
    });

    // Send OTP email
    try {
      await sendUniversityRegistrationOtpEmail({
        universityName: university.universityName,
        email: normalizedOfficialEmail,
        otp,
      });
    } catch (emailError) {
      console.error('Email sending failed during university creation:', emailError.message);
      await OtpVerification.deleteMany({ userId: user._id });
      await University.deleteOne({ _id: university._id });
      await User.deleteOne({ _id: user._id });
      return res.status(503).json({
        success: false,
        message: 'Unable to send verification code. Please check email configuration.',
      });
    }

    return res.status(201).json({
      success: true,
      message: 'A verification code has been sent to the university\'s official email address.',
      data: {
        universityId: university._id,
        userId: user._id,
        officialEmail: normalizedOfficialEmail,
        universityName: university.universityName,
        desiredStatus: initialStatus,
        requiresOtp: true,
      },
    });
  } catch (error) {
    return next(error);
  }
}

// 2. VERIFY UNIVERSITY OTP
async function verifyUniversityOtp(req, res, next) {
  try {
    const { universityId, userId, email, otp, desiredStatus } = req.body;
    if (!otp || !/^\d{6}$/.test(String(otp).trim())) {
      return res.status(400).json({ success: false, message: 'Invalid verification code.' });
    }

    // Resolve target university and user
    let university;
    if (universityId) {
      university = await University.findById(universityId);
    } else if (userId) {
      university = await University.findOne({ userId });
    } else if (email) {
      university = await University.findOne({ officialEmail: String(email).toLowerCase().trim() });
    }

    if (!university) {
      return res.status(404).json({ success: false, message: 'University account not found.' });
    }

    const targetUserId = university.userId;
    const user = await User.findById(targetUserId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Linked user account not found.' });
    }

    // Verify OTP using otpService
    await verifyOtp({
      userId: targetUserId,
      purpose: 'university_registration',
      otp: String(otp).trim(),
    });

    // Mark as verified & active
    const finalStatus = desiredStatus === 'inactive' ? 'inactive' : 'active';
    user.isEmailVerified = true;
    user.status = finalStatus;
    await user.save();

    university.status = finalStatus;
    await university.save();

    return res.json({
      success: true,
      message: 'University account created successfully.',
      data: university,
    });
  } catch (error) {
    return next(error);
  }
}

// 3. RESEND UNIVERSITY OTP
async function resendUniversityOtp(req, res, next) {
  try {
    const { universityId, userId, email } = req.body;
    let university;
    if (universityId) {
      university = await University.findById(universityId);
    } else if (userId) {
      university = await University.findOne({ userId });
    } else if (email) {
      university = await University.findOne({ officialEmail: String(email).toLowerCase().trim() });
    }

    if (!university) {
      return res.status(404).json({ success: false, message: 'University account not found.' });
    }

    const user = await User.findById(university.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User account not found.' });
    }

    // Check cooldown
    const { allowed, retryAfterSeconds } = await canResendOtp({
      userId: user._id,
      purpose: 'university_registration',
    });
    if (!allowed) {
      return res.status(429).json({
        success: false,
        message: `Please wait ${retryAfterSeconds} seconds before requesting a new code.`,
        retryAfterSeconds,
      });
    }

    // Delete existing unverified registration OTPs for this user
    await OtpVerification.deleteMany({ userId: user._id, purpose: 'university_registration' });

    // Generate new OTP
    const { otp } = await createOtpRecord({
      userId: user._id,
      purpose: 'university_registration',
      overrideExpiryMs: 5 * 60 * 1000,
    });

    try {
      await sendUniversityRegistrationOtpEmail({
        universityName: university.universityName,
        email: university.officialEmail,
        otp,
      });
    } catch (err) {
      return res.status(503).json({
        success: false,
        message: 'Unable to send verification code. Please try again.',
      });
    }

    return res.json({
      success: true,
      message: 'A new verification code has been sent.',
      data: { retryAfterSeconds: 60 },
    });
  } catch (error) {
    return next(error);
  }
}

// 4. LIST UNIVERSITIES
async function listUniversities(req, res, next) {
  try {
    const { search, status } = req.query;
    const filter = {};

    if (status && status !== 'all' && status !== 'All') {
      if (status.toLowerCase() === 'pending verification' || status.toLowerCase() === 'pending_verification') {
        filter.status = { $in: ['pending', 'pending_verification'] };
      } else {
        filter.status = status.toLowerCase();
      }
    }

    if (search && String(search).trim()) {
      const q = String(search).trim();
      filter.$or = [
        { universityName: { $regex: q, $options: 'i' } },
        { location: { $regex: q, $options: 'i' } },
        { officialEmail: { $regex: q, $options: 'i' } },
      ];
    }

    const universities = await University.find(filter)
      .populate('userId', 'fullName email role status isEmailVerified')
      .sort({ createdAt: -1 })
      .lean();

    return res.json({
      success: true,
      count: universities.length,
      data: universities,
    });
  } catch (error) {
    return next(error);
  }
}

// 5. GET SINGLE UNIVERSITY
async function getUniversity(req, res, next) {
  try {
    const university = await University.findById(req.params.id)
      .populate('userId', 'fullName email role status isEmailVerified')
      .lean();

    if (!university) {
      return res.status(404).json({ success: false, message: 'University not found' });
    }

    return res.json({ success: true, data: university });
  } catch (error) {
    return next(error);
  }
}

// 6. UPDATE UNIVERSITY
async function updateUniversity(req, res, next) {
  try {
    const university = await University.findById(req.params.id);
    if (!university) {
      return res.status(404).json({ success: false, message: 'University not found' });
    }

    const {
      universityName,
      location,
      officialEmail,
      address,
      contactNumber,
      representativeName,
      representativeEmail,
      representativeContactNumber,
      status,
      universityType,
    } = req.body;

    // Check duplicate officialEmail if changing
    if (officialEmail && officialEmail.toLowerCase().trim() !== university.officialEmail) {
      const newEmail = officialEmail.toLowerCase().trim();
      const existingUser = await User.findOne({ email: newEmail, _id: { $ne: university.userId } });
      const existingUni = await University.findOne({ officialEmail: newEmail, _id: { $ne: university._id } });
      if (existingUser || existingUni) {
        return res.status(409).json({ success: false, message: 'An account already exists with this email.' });
      }
      university.officialEmail = newEmail;
      const user = await User.findById(university.userId);
      if (user) {
        user.email = newEmail;
        await user.save();
      }
    }

    if (universityName) university.universityName = String(universityName).trim();
    if (location) university.location = String(location).trim();
    if (address) university.address = String(address).trim();
    if (contactNumber) university.contactNumber = String(contactNumber).trim();
    if (representativeName) university.representativeName = String(representativeName).trim();
    if (representativeEmail !== undefined) university.representativeEmail = String(representativeEmail).trim();
    if (representativeContactNumber) university.representativeContactNumber = String(representativeContactNumber).trim();
    if (universityType) university.universityType = String(universityType).trim();

    if (status) {
      const normalizedStatus = String(status).toLowerCase().trim();
      university.status = normalizedStatus;
      const user = await User.findById(university.userId);
      if (user) {
        user.status = normalizedStatus === 'inactive' ? 'inactive' : 'active';
        await user.save();
      }
    }

    await university.save();

    const populated = await University.findById(university._id)
      .populate('userId', 'fullName email role status isEmailVerified')
      .lean();

    return res.json({
      success: true,
      message: 'University updated successfully',
      data: populated,
    });
  } catch (error) {
    return next(error);
  }
}

// 7. DELETE UNIVERSITY
async function deleteUniversity(req, res, next) {
  try {
    const university = await University.findById(req.params.id);
    if (!university) {
      return res.status(404).json({ success: false, message: 'University not found' });
    }

    const userId = university.userId;
    await OtpVerification.deleteMany({ userId });
    await University.deleteOne({ _id: university._id });
    if (userId) {
      await User.deleteOne({ _id: userId });
    }

    return res.json({ success: true, message: 'University deleted successfully.' });
  } catch (error) {
    return next(error);
  }
}

// 8. UPDATE UNIVERSITY STATUS (Activate / Deactivate)
async function updateUniversityStatus(req, res, next) {
  try {
    const { status } = req.body;
    if (!status || !['active', 'inactive'].includes(status.toLowerCase())) {
      return res.status(400).json({ success: false, message: 'Valid status (active or inactive) is required.' });
    }

    const university = await University.findById(req.params.id);
    if (!university) {
      return res.status(404).json({ success: false, message: 'University not found' });
    }

    const newStatus = status.toLowerCase();
    university.status = newStatus;
    await university.save();

    const user = await User.findById(university.userId);
    if (user) {
      user.status = newStatus;
      await user.save();
    }

    const populated = await University.findById(university._id)
      .populate('userId', 'fullName email role status isEmailVerified')
      .lean();

    return res.json({
      success: true,
      message: `University account ${newStatus === 'active' ? 'activated' : 'deactivated'} successfully.`,
      data: populated,
    });
  } catch (error) {
    return next(error);
  }
}

// 9. UNIVERSITY STATISTICS
async function getUniversityStatistics(_req, res, next) {
  try {
    const total = await University.countDocuments({});
    const active = await University.countDocuments({ status: 'active' });
    const inactive = await University.countDocuments({ status: 'inactive' });
    const pending = await University.countDocuments({ status: { $in: ['pending', 'pending_verification'] } });

    return res.json({
      success: true,
      data: {
        totalUniversities: total,
        activeUniversities: active,
        inactiveUniversities: inactive,
        pendingVerification: pending,
      },
    });
  } catch (error) {
    return next(error);
  }
}

// 10. UNIVERSITY DASHBOARD
async function getUniversityDashboard(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required' });
    }
    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found' });
    }
    const user = await User.findById(req.user.userId).lean();

    const completion = calculateProfileCompletion(university);

    const courseRegex = new RegExp(`^${escapeRegex(university.universityName.trim())}$`, 'i');
    const courseCount = await Course.countDocuments({
      university: courseRegex,
      isActive: true,
    });

    const notifications = [];
    if (completion.percentage < 100) {
      notifications.push({
        id: 'notif_complete_profile',
        title: 'Complete Your Profile',
        message: 'Complete your profile to improve your university presence on CareerIQ.',
        type: 'warning',
        timestamp: university.updatedAt || university.createdAt,
      });
    }
    if (user?.isEmailVerified) {
      notifications.push({
        id: 'notif_verified',
        title: 'Account Verified',
        message: 'Your official email has been verified successfully.',
        type: 'success',
        timestamp: university.createdAt,
      });
    }

    const recentActivity = [
      {
        id: 'act_created',
        title: 'University Account Created',
        description: 'Account registered on CareerIQ Platform',
        timestamp: university.createdAt,
      },
    ];
    if (university.updatedAt && university.updatedAt.getTime() !== university.createdAt.getTime()) {
      recentActivity.unshift({
        id: 'act_updated',
        title: 'Profile Updated',
        description: 'University profile details were updated',
        timestamp: university.updatedAt,
      });
    }

    return res.json({
      success: true,
      data: {
        university: {
          id: university._id,
          userId: university.userId,
          universityName: university.universityName,
          officialEmail: university.officialEmail,
          location: university.location,
          address: university.address,
          contactNumber: university.contactNumber,
          representativeName: university.representativeName,
          representativeEmail: university.representativeEmail,
          representativeContactNumber: university.representativeContactNumber,
          universityType: university.universityType,
          website: university.website,
          description: university.description,
          logo: university.logo,
          status: university.status,
          isEmailVerified: user ? user.isEmailVerified : false,
          createdAt: university.createdAt,
          updatedAt: university.updatedAt,
        },
        statistics: {
          profileCompletion: completion.percentage,
          completedFields: completion.completed,
          totalFields: completion.total,
          courseCount: courseCount,
          status: university.status,
        },
        notifications,
        recentActivity,
      },
    });
  } catch (error) {
    return next(error);
  }
}

// 11. UNIVERSITY PROFILE (For university role)
async function getUniversityProfile(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required' });
    }
    const university = await University.findOne({ userId: req.user.userId }).lean();
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found' });
    }
    const user = await User.findById(req.user.userId).lean();
    const completion = calculateProfileCompletion(university);

    return res.json({
      success: true,
      data: {
        ...university,
        id: university._id,
        isEmailVerified: user ? user.isEmailVerified : false,
        profileCompletion: completion.percentage,
      },
    });
  } catch (error) {
    return next(error);
  }
}

// 12. UPDATE UNIVERSITY PROFILE
async function updateUniversityProfile(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required' });
    }
    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found' });
    }

    const allowed = [
      'universityName',
      'location',
      'address',
      'contactNumber',
      'representativeName',
      'representativeEmail',
      'representativeContactNumber',
      'universityType',
      'website',
      'description',
      'logo',
    ];

    if (req.body.universityName !== undefined) {
      const name = String(req.body.universityName).trim();
      if (!name) {
        return res.status(400).json({ success: false, message: 'University Name is required.' });
      }
      university.universityName = name;
      const user = await User.findById(req.user.userId);
      if (user) {
        user.fullName = name;
        await user.save();
      }
    }

    for (const key of allowed) {
      if (key !== 'universityName' && req.body[key] !== undefined) {
        university[key] = typeof req.body[key] === 'string' ? req.body[key].trim() : req.body[key];
      }
    }

    await university.save();

    const user = await User.findById(req.user.userId).lean();
    const completion = calculateProfileCompletion(university);

    return res.json({
      success: true,
      message: 'University profile updated successfully',
      data: {
        ...university.toObject(),
        id: university._id,
        isEmailVerified: user ? user.isEmailVerified : false,
        profileCompletion: completion.percentage,
      },
    });
  } catch (error) {
    return next(error);
  }
}

// 13. UNIVERSITY COURSES (Associated with this university)
async function getUniversityCourses(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required' });
    }
    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found' });
    }

    const courseRegex = new RegExp(`^${escapeRegex(university.universityName.trim())}$`, 'i');
    const courses = await Course.find({
      university: courseRegex,
      isActive: true,
    }).sort({ createdAt: -1 }).lean();

    return res.json({
      success: true,
      data: courses,
      count: courses.length,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createUniversity,
  verifyUniversityOtp,
  resendUniversityOtp,
  listUniversities,
  getUniversity,
  updateUniversity,
  deleteUniversity,
  updateUniversityStatus,
  getUniversityStatistics,
  getUniversityDashboard,
  getUniversityProfile,
  updateUniversityProfile,
  getUniversityCourses,
};
