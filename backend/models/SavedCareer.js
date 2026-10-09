const mongoose = require('mongoose');

const PRIORITIES = ['High', 'Medium', 'Low'];

/**
 * One career on a student's personal shortlist, with their own note and
 * priority. Stored per user, so the same career can sit on many students'
 * shortlists, but only once on each one.
 */
const savedCareerSchema = new mongoose.Schema(
	{
		userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
		career: { type: mongoose.Schema.Types.ObjectId, ref: 'Career', required: true },
		note: { type: String, trim: true, maxlength: 300, default: '' },
		priority: { type: String, enum: PRIORITIES, default: 'Medium' },
	},
	{ timestamps: true },
);

// A career can be saved only once per student.
savedCareerSchema.index({ userId: 1, career: 1 }, { unique: true });

module.exports = mongoose.model('SavedCareer', savedCareerSchema);
module.exports.PRIORITIES = PRIORITIES;
