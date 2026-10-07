const { trackEvent } = require('../services/analyticsService');
const Student = require('../models/Student');

/**
 * Handle incoming event tracking from Flutter app
 * POST /api/analytics/track
 */
async function trackAnalyticsEvent(req, res, next) {
  try {
    const { eventType, universityId, courseId, scholarshipId, metadata } = req.body;
    if (!eventType || !universityId) {
      return res.status(400).json({
        success: false,
        message: 'eventType and universityId are required',
      });
    }

    let studentId = null;
    let userId = req.user ? req.user.userId : null;

    if (userId) {
      const student = await Student.findOne({ userId }).select('_id');
      if (student) {
        studentId = student._id;
      }
    }

    const ip = req.headers['x-forwarded-for'] || req.socket?.remoteAddress;

    const result = await trackEvent({
      eventType,
      universityId,
      studentId,
      userId,
      courseId,
      scholarshipId,
      metadata: metadata || {},
      ip,
    });

    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  trackAnalyticsEvent,
};

