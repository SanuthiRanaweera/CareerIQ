const mongoose = require('mongoose');
const Scholarship = require('../models/Scholarship');
const ScholarshipApplication = require('../models/ScholarshipApplication');
const University = require('../models/University');
const Student = require('../models/Student');
const Notification = require('../models/Notification');

function escapeRegex(text) {
  return String(text).replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
}

// Helper: auto-update expired active scholarships
async function syncExpiredScholarships(query = {}) {
  const now = new Date();
  await Scholarship.updateMany(
    {
      ...query,
      status: 'active',
      applicationDeadline: { $lt: now },
    },
    { $set: { status: 'expired' } }
  );
}

// ==================================================
// UNIVERSITY SCHOLARSHIP MANAGEMENT
// ==================================================

// 1. CREATE SCHOLARSHIP (University Only)
async function createScholarship(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University representative access required.' });
    }

    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found.' });
    }

    const {
      title,
      description,
      scholarshipType,
      amount,
      coverage,
      numberOfScholarships,
      applicationDeadline,
      startDate,
      endDate,
      eligibility,
      applicationInstructions,
      requiredDocuments,
      status: requestedStatus,
    } = req.body;

    // Field validations
    if (!title || !String(title).trim()) {
      return res.status(400).json({ success: false, message: 'Scholarship Name is required.' });
    }
    if (!description || !String(description).trim()) {
      return res.status(400).json({ success: false, message: 'Description is required.' });
    }
    if (!scholarshipType || !String(scholarshipType).trim()) {
      return res.status(400).json({ success: false, message: 'Scholarship Type is required.' });
    }
    if (!amount || !String(amount).trim()) {
      return res.status(400).json({ success: false, message: 'Amount / Benefit is required.' });
    }
    if (!coverage || !Array.isArray(coverage) || coverage.length === 0) {
      return res.status(400).json({ success: false, message: 'At least one coverage item is required.' });
    }
    const num = Number(numberOfScholarships);
    if (isNaN(num) || num < 1) {
      return res.status(400).json({ success: false, message: 'Number of Scholarships must be at least 1.' });
    }
    if (!applicationDeadline) {
      return res.status(400).json({ success: false, message: 'Application Deadline is required.' });
    }

    const deadlineDate = new Date(applicationDeadline);
    if (isNaN(deadlineDate.getTime())) {
      return res.status(400).json({ success: false, message: 'Invalid Application Deadline date.' });
    }

    const initialStatus = requestedStatus ? requestedStatus.toLowerCase().trim() : 'active';
    if (initialStatus === 'active' && deadlineDate < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Application Deadline cannot be in the past when activating a scholarship.',
      });
    }

    const scholarship = await Scholarship.create({
      universityId: university._id,
      universityName: university.universityName,
      title: String(title).trim(),
      description: String(description).trim(),
      scholarshipType: String(scholarshipType).trim(),
      amount: String(amount).trim(),
      coverage: coverage.map((c) => String(c).trim()).filter(Boolean),
      numberOfScholarships: num,
      applicationDeadline: deadlineDate,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      eligibility: {
        stream: eligibility?.stream || 'Any',
        minimumResults: Array.isArray(eligibility?.minimumResults)
          ? eligibility.minimumResults.map((r) => ({
              subject: String(r.subject || '').trim(),
              grade: String(r.grade || '').trim(),
            })).filter((r) => r.subject && r.grade)
          : [],
        academicRequirement: eligibility?.academicRequirement || '',
        ageRequirement: eligibility?.ageRequirement || '',
        districtRequirement: eligibility?.districtRequirement || '',
        otherRequirements: eligibility?.otherRequirements || '',
      },
      applicationInstructions: applicationInstructions ? String(applicationInstructions).trim() : '',
      requiredDocuments: Array.isArray(requiredDocuments)
        ? requiredDocuments.map((d) => String(d).trim()).filter(Boolean)
        : [],
      status: initialStatus,
    });

    return res.status(201).json({
      success: true,
      message: 'Scholarship created successfully.',
      data: scholarship,
    });
  } catch (error) {
    return next(error);
  }
}

// 2. LIST UNIVERSITY'S OWN SCHOLARSHIPS
async function getUniversityScholarships(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required.' });
    }

    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found.' });
    }

    await syncExpiredScholarships({ universityId: university._id });

    const { status, type, search } = req.query;
    const filter = { universityId: university._id };

    if (status && status !== 'all' && status !== 'All') {
      filter.status = status.toLowerCase().trim();
    }
    if (type && type !== 'all' && type !== 'All') {
      filter.scholarshipType = type.trim();
    }
    if (search && String(search).trim()) {
      filter.title = { $regex: escapeRegex(search.trim()), $options: 'i' };
    }

    const scholarships = await Scholarship.find(filter).sort({ createdAt: -1 }).lean();

    // Attach real applicationsCount from MongoDB
    const enriched = await Promise.all(
      scholarships.map(async (s) => {
        const applicationsCount = await ScholarshipApplication.countDocuments({ scholarshipId: s._id });
        return {
          ...s,
          id: s._id.toString(),
          applicationsCount,
        };
      })
    );

    return res.json({
      success: true,
      count: enriched.length,
      data: enriched,
    });
  } catch (error) {
    return next(error);
  }
}

// 3. UNIVERSITY SCHOLARSHIP STATS (for dashboard)
async function getUniversityScholarshipStats(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required.' });
    }

    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found.' });
    }

    await syncExpiredScholarships({ universityId: university._id });

    const totalScholarships = await Scholarship.countDocuments({ universityId: university._id });
    const activeScholarships = await Scholarship.countDocuments({ universityId: university._id, status: 'active' });
    const closedScholarships = await Scholarship.countDocuments({ universityId: university._id, status: 'closed' });
    const expiredScholarships = await Scholarship.countDocuments({ universityId: university._id, status: 'expired' });
    const applicationsReceived = await ScholarshipApplication.countDocuments({ universityId: university._id });
    const pendingApplications = await ScholarshipApplication.countDocuments({ universityId: university._id, status: 'pending' });

    return res.json({
      success: true,
      data: {
        totalScholarships,
        activeScholarships,
        closedScholarships,
        expiredScholarships,
        applicationsReceived,
        pendingApplications,
      },
    });
  } catch (error) {
    return next(error);
  }
}

// 4. GET SINGLE SCHOLARSHIP FOR UNIVERSITY
async function getUniversityScholarshipById(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required.' });
    }

    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found.' });
    }

    const scholarship = await Scholarship.findOne({
      _id: req.params.id,
      universityId: university._id,
    }).lean();

    if (!scholarship) {
      return res.status(404).json({ success: false, message: 'Scholarship not found or unauthorized.' });
    }

    const applicationsCount = await ScholarshipApplication.countDocuments({ scholarshipId: scholarship._id });

    return res.json({
      success: true,
      data: {
        ...scholarship,
        id: scholarship._id.toString(),
        applicationsCount,
      },
    });
  } catch (error) {
    return next(error);
  }
}

// 5. UPDATE SCHOLARSHIP (University Owner Only)
async function updateScholarship(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required.' });
    }

    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found.' });
    }

    const scholarship = await Scholarship.findOne({
      _id: req.params.id,
      universityId: university._id,
    });

    if (!scholarship) {
      return res.status(404).json({ success: false, message: 'Scholarship not found or unauthorized.' });
    }

    const {
      title,
      description,
      scholarshipType,
      amount,
      coverage,
      numberOfScholarships,
      applicationDeadline,
      startDate,
      endDate,
      eligibility,
      applicationInstructions,
      requiredDocuments,
      status,
    } = req.body;

    if (title !== undefined) scholarship.title = String(title).trim();
    if (description !== undefined) scholarship.description = String(description).trim();
    if (scholarshipType !== undefined) scholarship.scholarshipType = String(scholarshipType).trim();
    if (amount !== undefined) scholarship.amount = String(amount).trim();
    if (coverage !== undefined && Array.isArray(coverage)) {
      scholarship.coverage = coverage.map((c) => String(c).trim()).filter(Boolean);
    }
    if (numberOfScholarships !== undefined) {
      const num = Number(numberOfScholarships);
      if (isNaN(num) || num < 1) {
        return res.status(400).json({ success: false, message: 'Number of scholarships must be at least 1.' });
      }
      scholarship.numberOfScholarships = num;
    }
    if (applicationDeadline !== undefined) {
      const deadlineDate = new Date(applicationDeadline);
      if (isNaN(deadlineDate.getTime())) {
        return res.status(400).json({ success: false, message: 'Invalid Application Deadline.' });
      }
      scholarship.applicationDeadline = deadlineDate;
    }
    if (startDate !== undefined) scholarship.startDate = startDate ? new Date(startDate) : undefined;
    if (endDate !== undefined) scholarship.endDate = endDate ? new Date(endDate) : undefined;
    if (eligibility !== undefined) scholarship.eligibility = eligibility;
    if (applicationInstructions !== undefined) scholarship.applicationInstructions = String(applicationInstructions).trim();
    if (requiredDocuments !== undefined && Array.isArray(requiredDocuments)) {
      scholarship.requiredDocuments = requiredDocuments.map((d) => String(d).trim()).filter(Boolean);
    }

    if (status !== undefined) {
      const targetStatus = String(status).toLowerCase().trim();
      if (targetStatus === 'active' && scholarship.applicationDeadline < new Date()) {
        return res.status(400).json({
          success: false,
          message: 'Cannot activate an expired scholarship. Please update deadline first.',
        });
      }
      scholarship.status = targetStatus;
    }

    await scholarship.save();

    return res.json({
      success: true,
      message: 'Scholarship updated successfully.',
      data: scholarship,
    });
  } catch (error) {
    return next(error);
  }
}

// 6. DELETE SCHOLARSHIP (University Owner Only)
async function deleteScholarship(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required.' });
    }

    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found.' });
    }

    const scholarship = await Scholarship.findOne({
      _id: req.params.id,
      universityId: university._id,
    });

    if (!scholarship) {
      return res.status(404).json({ success: false, message: 'Scholarship not found or unauthorized.' });
    }

    await ScholarshipApplication.deleteMany({ scholarshipId: scholarship._id });
    await Scholarship.deleteOne({ _id: scholarship._id });

    return res.json({ success: true, message: 'Scholarship deleted successfully.' });
  } catch (error) {
    return next(error);
  }
}

// 7. TOGGLE / UPDATE SCHOLARSHIP STATUS
async function updateScholarshipStatus(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required.' });
    }

    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found.' });
    }

    const scholarship = await Scholarship.findOne({
      _id: req.params.id,
      universityId: university._id,
    });

    if (!scholarship) {
      return res.status(404).json({ success: false, message: 'Scholarship not found or unauthorized.' });
    }

    const targetStatus = String(req.body.status || '').toLowerCase().trim();
    if (!['draft', 'active', 'closed', 'expired'].includes(targetStatus)) {
      return res.status(400).json({ success: false, message: 'Invalid status value.' });
    }

    if (targetStatus === 'active' && scholarship.applicationDeadline < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot activate scholarship with a past deadline.',
      });
    }

    scholarship.status = targetStatus;
    await scholarship.save();

    return res.json({
      success: true,
      message: `Scholarship status changed to ${targetStatus}.`,
      data: scholarship,
    });
  } catch (error) {
    return next(error);
  }
}

// 8. LIST APPLICATIONS FOR UNIVERSITY (All or for a scholarship)
async function getUniversityApplications(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required.' });
    }

    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found.' });
    }

    const filter = { universityId: university._id };
    if (req.params.id) {
      filter.scholarshipId = req.params.id;
    } else if (req.query.scholarshipId) {
      filter.scholarshipId = req.query.scholarshipId;
    }

    if (req.query.status && req.query.status !== 'all' && req.query.status !== 'All') {
      filter.status = req.query.status.toLowerCase().trim();
    }

    const applications = await ScholarshipApplication.find(filter)
      .populate('scholarshipId', 'title scholarshipType amount applicationDeadline')
      .sort({ createdAt: -1 })
      .lean();

    return res.json({
      success: true,
      count: applications.length,
      data: applications.map((a) => ({
        ...a,
        id: a._id.toString(),
      })),
    });
  } catch (error) {
    return next(error);
  }
}

// 9. GET SINGLE APPLICATION DETAILS FOR UNIVERSITY
async function getUniversityApplicationById(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required.' });
    }

    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found.' });
    }

    const application = await ScholarshipApplication.findOne({
      _id: req.params.id,
      universityId: university._id,
    })
      .populate('scholarshipId')
      .populate('studentId')
      .lean();

    if (!application) {
      return res.status(404).json({ success: false, message: 'Application not found or unauthorized.' });
    }

    return res.json({
      success: true,
      data: {
        ...application,
        id: application._id.toString(),
      },
    });
  } catch (error) {
    return next(error);
  }
}

// 10. UPDATE APPLICATION STATUS (University Review)
async function updateApplicationStatus(req, res, next) {
  try {
    if (req.user?.role !== 'university') {
      return res.status(403).json({ success: false, message: 'University access required.' });
    }

    const university = await University.findOne({ userId: req.user.userId });
    if (!university) {
      return res.status(404).json({ success: false, message: 'University profile not found.' });
    }

    const { status, reviewNotes } = req.body;
    const normalizedStatus = String(status || '').toLowerCase().trim();
    const validStatuses = ['pending', 'under_review', 'shortlisted', 'approved', 'rejected'];

    if (!validStatuses.includes(normalizedStatus)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Choose one of: ${validStatuses.join(', ')}`,
      });
    }

    const application = await ScholarshipApplication.findOne({
      _id: req.params.id,
      universityId: university._id,
    }).populate('scholarshipId');

    if (!application) {
      return res.status(404).json({ success: false, message: 'Application not found or unauthorized.' });
    }

    application.status = normalizedStatus;
    if (reviewNotes !== undefined) application.reviewNotes = String(reviewNotes).trim();
    await application.save();

    // Send real in-app notification to the student via Notification model
    const scholarshipTitle = application.scholarshipId?.title || 'Scholarship';
    let notifTitle = 'Scholarship Application Update';
    let notifMessage = `Your scholarship application for ${scholarshipTitle} has been updated to ${normalizedStatus.replace('_', ' ')}.`;

    if (normalizedStatus === 'approved') {
      notifTitle = 'Scholarship Application Approved';
      notifMessage = `Your application for ${scholarshipTitle} has been approved.`;
    } else if (normalizedStatus === 'rejected') {
      notifTitle = 'Scholarship Application Update';
      notifMessage = `Your application for ${scholarshipTitle} was not successful.`;
    } else if (normalizedStatus === 'under_review') {
      notifTitle = 'Scholarship Under Review';
      notifMessage = `Your scholarship application for ${scholarshipTitle} is currently under review.`;
    } else if (normalizedStatus === 'shortlisted') {
      notifTitle = 'Scholarship Application Shortlisted';
      notifMessage = `Your application for ${scholarshipTitle} has been shortlisted for further consideration.`;
    }

    try {
      await Notification.create({
        recipient: application.studentId,
        sentBy: req.user.userId,
        title: notifTitle,
        message: notifMessage,
      });
    } catch (notifErr) {
      console.error('Failed to create student notification:', notifErr.message);
    }

    return res.json({
      success: true,
      message: `Application status updated to ${normalizedStatus.replace('_', ' ')}.`,
      data: application,
    });
  } catch (error) {
    return next(error);
  }
}

// ==================================================
// STUDENT SCHOLARSHIP DISCOVERY & APPLICATIONS
// ==================================================

// 11. LIST SCHOLARSHIPS FOR STUDENTS (Public / Student browsing)
async function listScholarships(req, res, next) {
  try {
    await syncExpiredScholarships();

    const { search, type, stream, universityId, deadline } = req.query;
    const filter = { status: 'active' };

    // Search query across title, description, universityName
    if (search && String(search).trim()) {
      const q = String(search).trim();
      filter.$or = [
        { title: { $regex: escapeRegex(q), $options: 'i' } },
        { universityName: { $regex: escapeRegex(q), $options: 'i' } },
        { description: { $regex: escapeRegex(q), $options: 'i' } },
      ];
    }

    if (type && type !== 'all' && type !== 'All') {
      filter.scholarshipType = type.trim();
    }

    if (stream && stream !== 'all' && stream !== 'All') {
      filter.$and = filter.$and || [];
      filter.$and.push({
        $or: [
          { 'eligibility.stream': stream.trim() },
          { 'eligibility.stream': 'Any' },
        ],
      });
    }

    if (universityId) {
      filter.universityId = universityId;
    }

    // Sort by deadline closest first, then creation
    const scholarships = await Scholarship.find(filter)
      .sort({ applicationDeadline: 1, createdAt: -1 })
      .lean();

    // If student is logged in, mark which ones they've already applied for
    let studentAppliedSet = new Set();
    if (req.user?.userId && req.user.role === 'student') {
      const student = await Student.findOne({ userId: req.user.userId });
      if (student) {
        const applications = await ScholarshipApplication.find({ studentId: student._id }).select('scholarshipId').lean();
        studentAppliedSet = new Set(applications.map((a) => a.scholarshipId.toString()));
      }
    }

    const data = scholarships.map((s) => ({
      ...s,
      id: s._id.toString(),
      hasApplied: studentAppliedSet.has(s._id.toString()),
      isDeadlinePassed: new Date() > new Date(s.applicationDeadline),
    }));

    return res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    return next(error);
  }
}

// 12. GET SINGLE SCHOLARSHIP DETAILS FOR STUDENT
async function getScholarshipById(req, res, next) {
  try {
    await syncExpiredScholarships();

    const scholarship = await Scholarship.findById(req.params.id)
      .populate('universityId', 'universityName location officialEmail contactNumber website logo city district country')
      .lean();

    if (!scholarship) {
      return res.status(404).json({ success: false, message: 'Scholarship not found.' });
    }

    let hasApplied = false;
    let application = null;

    if (req.user?.userId && req.user.role === 'student') {
      const student = await Student.findOne({ userId: req.user.userId });
      if (student) {
        application = await ScholarshipApplication.findOne({
          scholarshipId: scholarship._id,
          studentId: student._id,
        }).lean();
        hasApplied = Boolean(application);
      }
    }

    const isDeadlinePassed = new Date() > new Date(scholarship.applicationDeadline);

    return res.json({
      success: true,
      data: {
        ...scholarship,
        id: scholarship._id.toString(),
        hasApplied,
        applicationId: application ? application._id.toString() : null,
        applicationStatus: application ? application.status : null,
        isDeadlinePassed,
      },
    });
  } catch (error) {
    return next(error);
  }
}

// 13. APPLY FOR SCHOLARSHIP (Student Only)
async function applyForScholarship(req, res, next) {
  try {
    if (req.user?.role !== 'student') {
      return res.status(403).json({ success: false, message: 'Only registered students can apply for scholarships.' });
    }

    const student = await Student.findOne({ userId: req.user.userId });
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student profile not found. Please complete profile first.' });
    }

    const scholarship = await Scholarship.findById(req.params.id);
    if (!scholarship) {
      return res.status(404).json({ success: false, message: 'Scholarship not found.' });
    }

    // Deadline validation
    if (new Date() > new Date(scholarship.applicationDeadline) || scholarship.status === 'closed' || scholarship.status === 'expired') {
      return res.status(400).json({
        success: false,
        message: 'Applications for this scholarship are closed.',
      });
    }

    // Check duplicate application
    const existing = await ScholarshipApplication.findOne({
      scholarshipId: scholarship._id,
      studentId: student._id,
    });
    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'You have already applied for this scholarship.',
      });
    }

    const { personalStatement, careerGoal, additionalInfo, documents } = req.body;

    if (!personalStatement || !String(personalStatement).trim()) {
      return res.status(400).json({
        success: false,
        message: 'Personal statement is required.',
      });
    }

    const application = await ScholarshipApplication.create({
      scholarshipId: scholarship._id,
      universityId: scholarship.universityId,
      studentId: student._id,
      userId: req.user.userId,
      studentName: student.fullName,
      studentEmail: student.email,
      studentSchool: student.school || '',
      studentDistrict: student.district || '',
      studentStream: student.stream || '',
      studentAlResults: student.alResults || [],
      personalStatement: String(personalStatement).trim(),
      careerGoal: careerGoal ? String(careerGoal).trim() : '',
      additionalInfo: additionalInfo ? String(additionalInfo).trim() : '',
      documents: Array.isArray(documents)
        ? documents.map((d) => ({
            name: String(d.name || '').trim(),
            fileName: String(d.fileName || '').trim(),
            fileUrl: String(d.fileUrl || '').trim(),
            uploadedAt: new Date(),
          })).filter((d) => d.name)
        : [],
      status: 'pending',
      submittedAt: new Date(),
    });

    try {
      const { trackEvent } = require('../services/analyticsService');
      trackEvent({
        eventType: 'scholarship_application',
        universityId: scholarship.universityId,
        scholarshipId: scholarship._id,
        studentId: student._id,
        userId: req.user.userId,
      }).catch((err) => console.error('Failed to track scholarship application event:', err.message));
    } catch (_) {}

    return res.status(201).json({
      success: true,
      message: 'Application submitted successfully!',
      data: application,
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'You have already applied for this scholarship.',
      });
    }
    return next(error);
  }
}

// 14. LIST MY SCHOLARSHIP APPLICATIONS (Student Only)
async function listStudentApplications(req, res, next) {
  try {
    if (req.user?.role !== 'student') {
      return res.status(403).json({ success: false, message: 'Student access required.' });
    }

    const student = await Student.findOne({ userId: req.user.userId });
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student profile not found.' });
    }

    const applications = await ScholarshipApplication.find({ studentId: student._id })
      .populate('scholarshipId', 'title scholarshipType amount applicationDeadline status coverage')
      .populate('universityId', 'universityName location logo')
      .sort({ createdAt: -1 })
      .lean();

    return res.json({
      success: true,
      count: applications.length,
      data: applications.map((a) => ({
        ...a,
        id: a._id.toString(),
      })),
    });
  } catch (error) {
    return next(error);
  }
}

// 15. GET SINGLE APPLICATION DETAILS FOR STUDENT
async function getStudentApplicationById(req, res, next) {
  try {
    if (req.user?.role !== 'student') {
      return res.status(403).json({ success: false, message: 'Student access required.' });
    }

    const student = await Student.findOne({ userId: req.user.userId });
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student profile not found.' });
    }

    const application = await ScholarshipApplication.findOne({
      _id: req.params.id,
      studentId: student._id,
    })
      .populate('scholarshipId')
      .populate('universityId')
      .lean();

    if (!application) {
      return res.status(404).json({ success: false, message: 'Application not found.' });
    }

    return res.json({
      success: true,
      data: {
        ...application,
        id: application._id.toString(),
      },
    });
  } catch (error) {
    return next(error);
  }
}

// ==================================================
// ADMIN SCHOLARSHIP MONITORING
// ==================================================

// 16. ADMIN ALL SCHOLARSHIPS
async function listAdminScholarships(req, res, next) {
  try {
    if (req.user?.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Administrator access required.' });
    }

    await syncExpiredScholarships();

    const scholarships = await Scholarship.find()
      .populate('universityId', 'universityName officialEmail location')
      .sort({ createdAt: -1 })
      .lean();

    const enriched = await Promise.all(
      scholarships.map(async (s) => {
        const applicationsCount = await ScholarshipApplication.countDocuments({ scholarshipId: s._id });
        return {
          ...s,
          id: s._id.toString(),
          applicationsCount,
        };
      })
    );

    return res.json({
      success: true,
      count: enriched.length,
      data: enriched,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createScholarship,
  getUniversityScholarships,
  getUniversityScholarshipStats,
  getUniversityScholarshipById,
  updateScholarship,
  deleteScholarship,
  updateScholarshipStatus,
  getUniversityApplications,
  getUniversityApplicationById,
  updateApplicationStatus,
  listScholarships,
  getScholarshipById,
  applyForScholarship,
  listStudentApplications,
  getStudentApplicationById,
  listAdminScholarships,
};

