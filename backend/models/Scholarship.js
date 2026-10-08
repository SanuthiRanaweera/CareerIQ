const mongoose = require('mongoose');

const requiredSubjectSchema = new mongoose.Schema(
  {
    subject: { type: String, required: true, trim: true },
    grade: { type: String, required: true, trim: true },
  },
  { _id: false }
);

const scholarshipSchema = new mongoose.Schema(
  {
    universityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'University',
      required: true,
      index: true,
    },
    universityName: {
      type: String,
      required: true,
      trim: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    description: {
      type: String,
      required: true,
      trim: true,
      maxlength: 3000,
    },
    scholarshipType: {
      type: String,
      required: true,
      enum: ['Merit', 'Need Based', 'Academic', 'Sports', 'Special Category', 'Other'],
      default: 'Merit',
      index: true,
    },
    amount: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    coverage: [
      {
        type: String,
        trim: true,
      },
    ],
    numberOfScholarships: {
      type: Number,
      required: true,
      min: 1,
    },
    applicationDeadline: {
      type: Date,
      required: true,
      index: true,
    },
    startDate: {
      type: Date,
    },
    endDate: {
      type: Date,
    },
    eligibility: {
      stream: {
        type: String,
        enum: ['Physical Science', 'Biological Science', 'Commerce', 'Arts', 'Technology', 'Any'],
        default: 'Any',
      },
      minimumResults: [requiredSubjectSchema],
      academicRequirement: {
        type: String,
        trim: true,
        default: '',
      },
      ageRequirement: {
        type: String,
        trim: true,
        default: '',
      },
      districtRequirement: {
        type: String,
        trim: true,
        default: '',
      },
      otherRequirements: {
        type: String,
        trim: true,
        default: '',
      },
    },
    applicationInstructions: {
      type: String,
      trim: true,
      default: '',
    },
    requiredDocuments: [
      {
        type: String,
        trim: true,
      },
    ],
    status: {
      type: String,
      enum: ['draft', 'active', 'closed', 'expired'],
      default: 'active',
      index: true,
    },
  },
  { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

scholarshipSchema.virtual('isExpired').get(function () {
  return this.applicationDeadline ? new Date() > new Date(this.applicationDeadline) : false;
});

// Dynamic status resolution
scholarshipSchema.methods.getEffectiveStatus = function () {
  if (this.status === 'draft') return 'draft';
  if (this.status === 'closed') return 'closed';
  if (this.applicationDeadline && new Date() > new Date(this.applicationDeadline)) {
    return 'expired';
  }
  return this.status;
};

scholarshipSchema.index({ title: 'text', description: 'text', universityName: 'text' });
scholarshipSchema.index({ status: 1, applicationDeadline: 1 });

module.exports = mongoose.model('Scholarship', scholarshipSchema);

