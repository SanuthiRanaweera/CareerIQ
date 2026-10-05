const mongoose = require('mongoose');

const universitySchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
    universityName: { type: String, required: true, trim: true, maxlength: 150 },
    officialEmail: { type: String, required: true, unique: true, lowercase: true, trim: true },
    contactNumber: { type: String, trim: true, maxlength: 30 },
    address: { type: String, trim: true, maxlength: 240 },
    city: { type: String, trim: true, maxlength: 80 },
    district: { type: String, trim: true, maxlength: 80 },
    country: { type: String, trim: true, maxlength: 80 },
    universityType: { type: String, enum: ['Government', 'Private', 'International', 'Other'], default: 'Other' },
    website: { type: String, trim: true, maxlength: 200 },
    description: { type: String, trim: true, maxlength: 600 },
    logo: { type: String, trim: true },
    status: { type: String, enum: ['active', 'inactive', 'pending'], default: 'pending' },
  },
  { timestamps: true },
);

module.exports = mongoose.model('University', universitySchema);
