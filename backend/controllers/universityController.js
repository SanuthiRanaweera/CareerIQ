const User = require('../models/User');
const University = require('../models/University');
const { createUniversityAccount } = require('../services/authService');

function normalizeUniversityPayload(body) {
  return {
    universityName: String(body.universityName || '').trim(),
    officialEmail: String(body.officialEmail || '').trim(),
    contactNumber: String(body.contactNumber || '').trim(),
    address: String(body.address || '').trim(),
    city: String(body.city || '').trim(),
    district: String(body.district || '').trim(),
    country: String(body.country || '').trim(),
    universityType: String(body.universityType || 'Other').trim(),
    website: String(body.website || '').trim(),
    description: String(body.description || '').trim(),
    logo: String(body.logo || '').trim(),
    status: String(body.status || 'pending').trim().toLowerCase(),
    password: body.password ? String(body.password) : undefined,
  };
}

async function createUniversity(req, res, next) {
  try {
    const payload = normalizeUniversityPayload(req.body);
    if (!payload.universityName || !payload.officialEmail) {
      throw Object.assign(new Error('University name and official email are required'), { statusCode: 400 });
    }
    const result = await createUniversityAccount(payload);
    return res.status(201).json({ success: true, message: 'University account created successfully. Login instructions have been sent to the registered email.', data: result });
  } catch (error) {
    return next(error);
  }
}

async function listUniversities(_req, res, next) {
  try {
    const universities = await University.find({}).sort({ universityName: 1 }).lean();
    return res.json({ success: true, data: universities });
  } catch (error) {
    return next(error);
  }
}

async function getUniversity(req, res, next) {
  try {
    const university = await University.findById(req.params.id).lean();
    if (!university) {
      return res.status(404).json({ success: false, message: 'University not found' });
    }
    return res.json({ success: true, data: university });
  } catch (error) {
    return next(error);
  }
}

async function updateUniversity(req, res, next) {
  try {
    const payload = normalizeUniversityPayload(req.body);
    const university = await University.findById(req.params.id);
    if (!university) return res.status(404).json({ success: false, message: 'University not found' });

    Object.assign(university, {
      universityName: payload.universityName || university.universityName,
      officialEmail: payload.officialEmail || university.officialEmail,
      contactNumber: payload.contactNumber || university.contactNumber,
      address: payload.address || university.address,
      city: payload.city || university.city,
      district: payload.district || university.district,
      country: payload.country || university.country,
      universityType: payload.universityType || university.universityType,
      website: payload.website || university.website,
      description: payload.description || university.description,
      logo: payload.logo || university.logo,
      status: payload.status || university.status,
    });

    await university.save();
    const user = await User.findById(university.userId);
    if (user && payload.status) {
      user.status = payload.status;
      await user.save();
    }
    return res.json({ success: true, message: 'University updated successfully', data: university });
  } catch (error) {
    return next(error);
  }
}

async function deleteUniversity(req, res, next) {
  try {
    const university = await University.findById(req.params.id);
    if (!university) return res.status(404).json({ success: false, message: 'University not found' });
    await User.deleteOne({ _id: university.userId });
    await university.deleteOne();
    return res.json({ success: true, message: 'University removed successfully' });
  } catch (error) {
    return next(error);
  }
}

async function getUniversityProfile(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required' });
    }
    const university = await University.findOne({ userId: req.user.userId }).lean();
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found' });
    }
    return res.json({ success: true, data: university });
  } catch (error) {
    return next(error);
  }
}

async function updateUniversityProfile(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required' });
    }
    const payload = normalizeUniversityPayload(req.body);
    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found' });
    }

    Object.assign(university, {
      universityName: payload.universityName || university.universityName,
      contactNumber: payload.contactNumber || university.contactNumber,
      address: payload.address || university.address,
      city: payload.city || university.city,
      district: payload.district || university.district,
      country: payload.country || university.country,
      universityType: payload.universityType || university.universityType,
      website: payload.website || university.website,
      description: payload.description || university.description,
      logo: payload.logo || university.logo,
    });

    await university.save();
    return res.json({ success: true, message: 'University profile updated successfully', data: university });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createUniversity,
  listUniversities,
  getUniversity,
  updateUniversity,
  deleteUniversity,
  getUniversityProfile,
  updateUniversityProfile,
};
