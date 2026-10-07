const mongoose = require('mongoose');

const analyticsEventSchema = new mongoose.Schema(
  {
    eventType: {
      type: String,
      required: true,
      enum: [
        'university_view',
        'course_view',
        'university_favourite',
        'university_interest',
        'course_interest',
        'scholarship_view',
        'scholarship_application',
        'comparison',
        'search_appearance',
      ],
      index: true,
    },
    universityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'University',
      required: true,
      index: true,
    },
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      default: null,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    courseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Course',
      default: null,
      index: true,
    },
    scholarshipId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Scholarship',
      default: null,
      index: true,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    ipHash: {
      type: String,
      default: null,
    },
    timestamp: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  { timestamps: true }
);

// High-performance compound indexes for real-time analytics aggregation
analyticsEventSchema.index({ universityId: 1, eventType: 1, timestamp: -1 });
analyticsEventSchema.index({ universityId: 1, timestamp: -1 });
analyticsEventSchema.index({ courseId: 1, eventType: 1, timestamp: -1 });
analyticsEventSchema.index({ scholarshipId: 1, eventType: 1, timestamp: -1 });

module.exports = mongoose.model('AnalyticsEvent', analyticsEventSchema);

