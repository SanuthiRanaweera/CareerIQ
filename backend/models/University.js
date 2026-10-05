const mongoose = require('mongoose');

const universitySchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
    universityName: { type: String, required: true, trim: true, maxlength: 150 },
    location: { type: String, required: true, trim: true, maxlength: 150 },
    officialEmail: { type: String, required: true, unique: true, lowercase: true, trim: true },
    address: { type: String, required: true, trim: true, maxlength: 250 },
    contactNumber: { type: String, required: true, trim: true, maxlength: 30 },
    representativeName: { type: String, required: true, trim: true, maxlength: 100 },
    representativeEmail: { type: String, trim: true, lowercase: true },
    representativeContactNumber: { type: String, required: true, trim: true, maxlength: 30 },
    universityType: { type: String, trim: true, default: 'State University' },
    website: { type: String, trim: true, maxlength: 200 },
    description: { type: String, trim: true, maxlength: 600 },
    logo: { type: String, trim: true },
    city: { type: String, trim: true, maxlength: 80 },
    district: { type: String, trim: true, maxlength: 80 },
    country: { type: String, trim: true, maxlength: 80 },
    status: {
      type: String,
      enum: ['active', 'inactive', 'pending', 'pending_verification'],
      default: 'pending_verification',
      index: true,
    },
  },
  { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } },
);

module.exports = mongoose.model('University', universitySchema);
