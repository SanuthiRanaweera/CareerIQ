const mongoose = require('mongoose');

const applicationDocumentSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    fileName: { type: String, trim: true, default: '' },
    fileUrl: { type: String, trim: true, default: '' },
    uploadedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const scholarshipApplicationSchema = new mongoose.Schema(
  {
    scholarshipId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Scholarship',
      required: true,
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
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    studentName: {
      type: String,
      required: true,
      trim: true,
    },
    studentEmail: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
    },
    studentSchool: {
      type: String,
      trim: true,
      default: '',
    },
    studentDistrict: {
      type: String,
      trim: true,
      default: '',
    },
    studentStream: {
      type: String,
      trim: true,
      default: '',
    },
    studentAlResults: [
      {
        name: { type: String, trim: true },
        grade: { type: String, trim: true },
      },
    ],
    personalStatement: {
      type: String,
      required: true,
      trim: true,
      maxlength: 3000,
    },
    careerGoal: {
      type: String,
      trim: true,
      default: '',
      maxlength: 2000,
    },
    additionalInfo: {
      type: String,
      trim: true,
      default: '',
      maxlength: 2000,
    },
    documents: [applicationDocumentSchema],
    status: {
      type: String,
      enum: ['pending', 'under_review', 'shortlisted', 'approved', 'rejected'],
      default: 'pending',
      index: true,
    },
    reviewNotes: {
      type: String,
      trim: true,
      default: '',
    },
    submittedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

// Prevent duplicate applications for the same scholarship by the same student
scholarshipApplicationSchema.index({ scholarshipId: 1, studentId: 1 }, { unique: true });
scholarshipApplicationSchema.index({ universityId: 1, status: 1 });
scholarshipApplicationSchema.index({ studentId: 1, createdAt: -1 });

module.exports = mongoose.model('ScholarshipApplication', scholarshipApplicationSchema);

