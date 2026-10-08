const crypto = require('crypto');
const mongoose = require('mongoose');
const AnalyticsEvent = require('../models/AnalyticsEvent');
const Student = require('../models/Student');
const Course = require('../models/Course');
const Scholarship = require('../models/Scholarship');
const ScholarshipApplication = require('../models/ScholarshipApplication');

function escapeRegex(text) {
  return String(text).replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
}

function hashIp(ip) {
  if (!ip) return null;
  return crypto.createHash('sha256').update(String(ip)).digest('hex').substring(0, 16);
}

/**
 * Record an analytics event with debouncing/deduplication for view events
 */
async function trackEvent({
  eventType,
  universityId,
  studentId = null,
  userId = null,
  courseId = null,
  scholarshipId = null,
  metadata = {},
  ip = null,
}) {
  if (!eventType || !universityId) {
    return { success: false, message: 'eventType and universityId are required' };
  }

  const validUniId = mongoose.Types.ObjectId.isValid(universityId)
    ? new mongoose.Types.ObjectId(universityId)
    : null;
  if (!validUniId) {
    return { success: false, message: 'Invalid universityId' };
  }

  const validCourseId = courseId && mongoose.Types.ObjectId.isValid(courseId)
    ? new mongoose.Types.ObjectId(courseId)
    : null;

  const validScholarshipId = scholarshipId && mongoose.Types.ObjectId.isValid(scholarshipId)
    ? new mongoose.Types.ObjectId(scholarshipId)
    : null;

  const validStudentId = studentId && mongoose.Types.ObjectId.isValid(studentId)
    ? new mongoose.Types.ObjectId(studentId)
    : null;

  const validUserId = userId && mongoose.Types.ObjectId.isValid(userId)
    ? new mongoose.Types.ObjectId(userId)
    : null;

  const ipHash = hashIp(ip);

  // View event debouncing (prevent multiple counts within 15 minutes from the same user/session/IP)
  const isViewEvent = ['university_view', 'course_view', 'scholarship_view'].includes(eventType);
  if (isViewEvent) {
    const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
    const debounceQuery = {
      eventType,
      universityId: validUniId,
      timestamp: { $gte: fifteenMinutesAgo },
    };

    if (validCourseId) debounceQuery.courseId = validCourseId;
    if (validScholarshipId) debounceQuery.scholarshipId = validScholarshipId;

    if (validStudentId || validUserId) {
      debounceQuery.$or = [
        ...(validStudentId ? [{ studentId: validStudentId }] : []),
        ...(validUserId ? [{ userId: validUserId }] : []),
        ...(ipHash ? [{ ipHash }] : []),
      ];
    } else if (ipHash) {
      debounceQuery.ipHash = ipHash;
    }

    const existingRecent = await AnalyticsEvent.findOne(debounceQuery);
    if (existingRecent) {
      return { success: true, deduplicated: true, id: existingRecent._id };
    }
  }

  const event = await AnalyticsEvent.create({
    eventType,
    universityId: validUniId,
    studentId: validStudentId,
    userId: validUserId,
    courseId: validCourseId,
    scholarshipId: validScholarshipId,
    metadata,
    ipHash,
    timestamp: new Date(),
  });

  return { success: true, deduplicated: false, id: event._id };
}

/**
 * Generate formatted dates between start and end
 */
function generateDateMap(startDate, endDate) {
  const map = new Map();
  const current = new Date(startDate);
  current.setHours(0, 0, 0, 0);

  const end = new Date(endDate);
  end.setHours(23, 59, 59, 999);

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  while (current <= end) {
    const y = current.getFullYear();
    const m = String(current.getMonth() + 1).padStart(2, '0');
    const d = String(current.getDate()).padStart(2, '0');
    const key = `${y}-${m}-${d}`;
    const label = `${months[current.getMonth()]} ${current.getDate()}`;
    const dayOfWeek = days[current.getDay()];

    map.set(key, { date: key, label, dayOfWeek, count: 0 });
    current.setDate(current.getDate() + 1);
  }

  return map;
}

/**
 * Retrieve comprehensive, real MongoDB analytics for a university
 */
async function getUniversityAnalytics({ universityId, universityName, range = '30d' }) {
  const uniId = new mongoose.Types.ObjectId(universityId);

  // 1. Determine date range
  let days = 30;
  if (range === '7d') days = 7;
  else if (range === '90d' || range === '3m') days = 90;
  else if (range === '1y' || range === '365d') days = 365;

  const now = new Date();
  const currentStart = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
  const previousStart = new Date(currentStart.getTime() - days * 24 * 60 * 60 * 1000);

  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

  // 2. Profile views aggregation
  const [
    currentViewsCount,
    previousViewsCount,
    todayViewsCount,
    weekViewsCount,
    monthViewsCount,
    allTimeViewsCount,
  ] = await Promise.all([
    AnalyticsEvent.countDocuments({
      universityId: uniId,
      eventType: 'university_view',
      timestamp: { $gte: currentStart, $lte: now },
    }),
    AnalyticsEvent.countDocuments({
      universityId: uniId,
      eventType: 'university_view',
      timestamp: { $gte: previousStart, $lt: currentStart },
    }),
    AnalyticsEvent.countDocuments({
      universityId: uniId,
      eventType: 'university_view',
      timestamp: { $gte: todayStart },
    }),
    AnalyticsEvent.countDocuments({
      universityId: uniId,
      eventType: 'university_view',
      timestamp: { $gte: sevenDaysAgo },
    }),
    AnalyticsEvent.countDocuments({
      universityId: uniId,
      eventType: 'university_view',
      timestamp: { $gte: thirtyDaysAgo },
    }),
    AnalyticsEvent.countDocuments({
      universityId: uniId,
      eventType: 'university_view',
    }),
  ]);

  // Calculate percentage growth safely
  let profileViewsTrend = null;
  if (previousViewsCount > 0) {
    profileViewsTrend = Number((((currentViewsCount - previousViewsCount) / previousViewsCount) * 100).toFixed(1));
  }

  // 3. Profile views timeline trend (group by day)
  const profileViewsDaily = await AnalyticsEvent.aggregate([
    {
      $match: {
        universityId: uniId,
        eventType: 'university_view',
        timestamp: { $gte: currentStart, $lte: now },
      },
    },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$timestamp' } },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const profileDateMap = generateDateMap(currentStart, now);
  for (const item of profileViewsDaily) {
    if (profileDateMap.has(item._id)) {
      profileDateMap.get(item._id).count = item.count;
    }
  }
  const profileViewsTrendData = Array.from(profileDateMap.values());

  // 4. Student Interest & Favourites
  const totalFavourites = await Student.countDocuments({
    favoriteUniversities: uniId,
  });

  const newFavouritesPeriod = await AnalyticsEvent.countDocuments({
    universityId: uniId,
    eventType: 'university_favourite',
    timestamp: { $gte: currentStart, $lte: now },
  });

  // Distinct interested students in this period
  const interestedStudentsDistinct = await AnalyticsEvent.aggregate([
    {
      $match: {
        universityId: uniId,
        studentId: { $ne: null },
        timestamp: { $gte: currentStart, $lte: now },
      },
    },
    {
      $group: {
        _id: '$studentId',
      },
    },
    {
      $count: 'total',
    },
  ]);
  const studentsInterestedCount = Math.max(
    interestedStudentsDistinct.length > 0 ? interestedStudentsDistinct[0].total : 0,
    totalFavourites,
  );

  // New interests this week and month
  const [newInterestsWeek, newInterestsMonth] = await Promise.all([
    AnalyticsEvent.countDocuments({
      universityId: uniId,
      eventType: { $in: ['university_favourite', 'university_interest'] },
      timestamp: { $gte: sevenDaysAgo },
    }),
    AnalyticsEvent.countDocuments({
      universityId: uniId,
      eventType: { $in: ['university_favourite', 'university_interest'] },
      timestamp: { $gte: thirtyDaysAgo },
    }),
  ]);

  // Favourites monthly trend
  const favouritesMonthlyAgg = await AnalyticsEvent.aggregate([
    {
      $match: {
        universityId: uniId,
        eventType: 'university_favourite',
        timestamp: { $gte: new Date(now.getFullYear(), now.getMonth() - 5, 1) },
      },
    },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m', date: '$timestamp' } },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  // 5. Courses Analytics
  const uniNameClean = (universityName || '').trim();
  const courseRegex = new RegExp(`^${escapeRegex(uniNameClean)}$`, 'i');
  const universityCourses = await Course.find({
    $or: [{ universityId: uniId }, { university: courseRegex }],
    isActive: true,
  }).lean();

  const courseIds = universityCourses.map((c) => c._id);

  // Total course views in current period
  const totalCourseViews = await AnalyticsEvent.countDocuments({
    $or: [
      { universityId: uniId, eventType: 'course_view' },
      { courseId: { $in: courseIds }, eventType: 'course_view' },
    ],
    timestamp: { $gte: currentStart, $lte: now },
  });

  // Course view trend (group by day)
  const courseViewsDaily = await AnalyticsEvent.aggregate([
    {
      $match: {
        $or: [
          { universityId: uniId, eventType: 'course_view' },
          { courseId: { $in: courseIds }, eventType: 'course_view' },
        ],
        timestamp: { $gte: currentStart, $lte: now },
      },
    },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$timestamp' } },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const courseDateMap = generateDateMap(currentStart, now);
  for (const item of courseViewsDaily) {
    if (courseDateMap.has(item._id)) {
      courseDateMap.get(item._id).count = item.count;
    }
  }
  const courseViewsTrendData = Array.from(courseDateMap.values());

  // Views per course
  const courseViewsAgg = await AnalyticsEvent.aggregate([
    {
      $match: {
        $or: [
          { universityId: uniId, eventType: 'course_view' },
          { courseId: { $in: courseIds }, eventType: 'course_view' },
        ],
        courseId: { $ne: null },
        timestamp: { $gte: currentStart, $lte: now },
      },
    },
    {
      $group: {
        _id: '$courseId',
        views: { $sum: 1 },
      },
    },
    { $sort: { views: -1 } },
    { $limit: 10 },
  ]);

  const courseViewsMap = new Map();
  courseViewsAgg.forEach((item) => courseViewsMap.set(String(item._id), item.views));

  // Build most viewed and popular courses
  const courseAnalyticsList = universityCourses.map((c) => {
    const cIdStr = String(c._id);
    const views = courseViewsMap.get(cIdStr) || 0;
    return {
      id: cIdStr,
      title: c.title,
      code: c.code || '',
      stream: c.stream || 'Other',
      degreeType: c.degreeType || 'BSc',
      durationYears: c.durationYears || 4,
      minZScore: c.minZScore,
      views,
      interest: Math.round(views * 0.25),
    };
  });

  // Sort by views descending
  courseAnalyticsList.sort((a, b) => b.views - a.views);

  // 6. Scholarship Analytics
  const [totalScholarships, activeScholarships] = await Promise.all([
    Scholarship.countDocuments({ universityId: uniId }),
    Scholarship.countDocuments({
      universityId: uniId,
      status: 'active',
      applicationDeadline: { $gte: now },
    }),
  ]);

  const totalApplications = await ScholarshipApplication.countDocuments({
    universityId: uniId,
  });

  const periodApplications = await ScholarshipApplication.countDocuments({
    universityId: uniId,
    createdAt: { $gte: currentStart, $lte: now },
  });

  // Application status breakdown
  const appStatusAgg = await ScholarshipApplication.aggregate([
    { $match: { universityId: uniId } },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
      },
    },
  ]);

  const applicationStatus = {
    pending: 0,
    underReview: 0,
    shortlisted: 0,
    approved: 0,
    rejected: 0,
  };

  appStatusAgg.forEach((item) => {
    const statusKey = String(item._id || '').toLowerCase();
    if (statusKey === 'pending') applicationStatus.pending = item.count;
    else if (statusKey === 'under_review' || statusKey === 'underreview') applicationStatus.underReview = item.count;
    else if (statusKey === 'shortlisted') applicationStatus.shortlisted = item.count;
    else if (statusKey === 'approved') applicationStatus.approved = item.count;
    else if (statusKey === 'rejected') applicationStatus.rejected = item.count;
  });

  // Scholarship performance (applications per scholarship)
  const scholarshipPerformanceAgg = await ScholarshipApplication.aggregate([
    {
      $match: {
        universityId: uniId,
      },
    },
    {
      $group: {
        _id: '$scholarshipId',
        applicationsCount: { $sum: 1 },
      },
    },
    { $sort: { applicationsCount: -1 } },
    { $limit: 10 },
  ]);

  const scholarshipPerformanceIds = scholarshipPerformanceAgg.map((s) => s._id);
  const matchedScholarships = await Scholarship.find({
    _id: { $in: scholarshipPerformanceIds },
  }).lean();

  const scholarshipMap = new Map();
  matchedScholarships.forEach((s) => scholarshipMap.set(String(s._id), s));

  const scholarshipPerformance = scholarshipPerformanceAgg.map((item) => {
    const s = scholarshipMap.get(String(item._id));
    return {
      id: String(item._id),
      title: s ? s.title : 'Scholarship',
      scholarshipType: s ? s.scholarshipType : 'General',
      amount: s ? s.amount : '',
      applications: item.applicationsCount,
    };
  });

  // Scholarship application timeline trend
  const appTrendDaily = await ScholarshipApplication.aggregate([
    {
      $match: {
        universityId: uniId,
        createdAt: { $gte: currentStart, $lte: now },
      },
    },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const appDateMap = generateDateMap(currentStart, now);
  for (const item of appTrendDaily) {
    if (appDateMap.has(item._id)) {
      appDateMap.get(item._id).count = item.count;
    }
  }
  const scholarshipApplicationsTrendData = Array.from(appDateMap.values());

  // 7. Comparison activity
  const comparisonCount = await AnalyticsEvent.countDocuments({
    universityId: uniId,
    eventType: 'comparison',
    timestamp: { $gte: currentStart, $lte: now },
  });

  // 8. Search discovery appearances
  const searchAppearances = await AnalyticsEvent.countDocuments({
    universityId: uniId,
    eventType: 'search_appearance',
    timestamp: { $gte: currentStart, $lte: now },
  });

  return {
    range,
    overview: {
      profileViews: currentViewsCount,
      studentsInterested: studentsInterestedCount,
      favourites: totalFavourites,
      courseViews: totalCourseViews,
      scholarshipApplications: periodApplications,
      totalApplications,
      comparisons: comparisonCount,
      searchAppearances,
    },
    profileViews: {
      current: currentViewsCount,
      previous: previousViewsCount,
      trend: profileViewsTrend,
      today: todayViewsCount,
      thisWeek: weekViewsCount,
      thisMonth: monthViewsCount,
      allTime: allTimeViewsCount,
    },
    studentInterest: {
      total: studentsInterestedCount,
      newThisWeek: newInterestsWeek,
      newThisMonth: newInterestsMonth,
    },
    favourites: {
      total: totalFavourites,
      newInPeriod: newFavouritesPeriod,
      trend: favouritesMonthlyAgg.map((item) => ({
        month: item._id,
        count: item.count,
      })),
    },
    courses: {
      total: universityCourses.length,
      totalViews: totalCourseViews,
      mostViewed: courseAnalyticsList.slice(0, 5),
      popularCourses: courseAnalyticsList,
    },
    scholarships: {
      total: totalScholarships,
      active: activeScholarships,
      applications: totalApplications,
      periodApplications,
      performance: scholarshipPerformance,
    },
    applicationStatus,
    comparisonActivity: {
      selectedCount: comparisonCount,
    },
    searchDiscovery: {
      searchAppearances,
      profileViews: currentViewsCount,
      rate: searchAppearances > 0 ? Number(((currentViewsCount / searchAppearances) * 100).toFixed(1)) : 0,
    },
    trends: {
      profileViews: profileViewsTrendData,
      scholarshipApplications: scholarshipApplicationsTrendData,
      courseViews: courseViewsTrendData,
    },
  };
}

module.exports = {
  trackEvent,
  getUniversityAnalytics,
};

