const mongoose = require('mongoose');
const { AL_STREAMS, PERSONALITY_TYPES, WORK_STYLES, JOB_OUTLOOKS } = require('../data/careerOptions');

// Reusable validator: guarantees a list field was actually filled in, because
// Mongoose treats an empty array as a valid value for `required`.
function nonEmptyArray(values) {
	return Array.isArray(values) && values.length > 0;
}

/**
 * One ordered step on the road to a career, e.g.
 * A/L Stream -> Degree -> Skills -> Internship -> Entry Job -> Senior Role.
 * `stage` is free text rather than an enum so that careers needing an unusual
 * step (a professional certification, a licensing exam) are not blocked.
 */
const pathwayStepSchema = new mongoose.Schema(
	{
		order: { type: Number, required: true, min: 1 },
		stage: { type: String, required: true, trim: true, maxlength: 60 },
		title: { type: String, required: true, trim: true, maxlength: 120 },
		description: { type: String, trim: true, maxlength: 400 },
		durationLabel: { type: String, trim: true, maxlength: 40 },
	},
	{ _id: false },
);

// Monthly salary band in Sri Lankan Rupees.
const salaryRangeSchema = new mongoose.Schema(
	{
		min: { type: Number, required: true, min: 0 },
		max: { type: Number, required: true, min: 0 },
		currency: { type: String, default: 'LKR', trim: true, uppercase: true, maxlength: 5 },
		period: { type: String, enum: ['month', 'year'], default: 'month' },
	},
	{ _id: false },
);

const careerSchema = new mongoose.Schema(
	{
		title: { type: String, required: true, unique: true, trim: true, maxlength: 120 },
		category: { type: String, required: true, trim: true, maxlength: 80, index: true },
		description: { type: String, required: true, trim: true, maxlength: 1000 },

		// Day-to-day responsibilities shown under "What you'd do" on the details screen.
		whatYouDo: {
			type: [{ type: String, trim: true, maxlength: 200 }],
			validate: [nonEmptyArray, 'At least one day-to-day responsibility is required'],
		},
		requiredSkills: {
			type: [{ type: String, trim: true, maxlength: 60 }],
			validate: [nonEmptyArray, 'At least one required skill is required'],
		},
		recommendedStreams: {
			type: [{ type: String, enum: AL_STREAMS }],
			validate: [nonEmptyArray, 'At least one recommended A/L stream is required'],
		},

		salaryRange: {
			type: salaryRangeSchema,
			required: true,
			validate: {
				validator: (range) => !range || range.max >= range.min,
				message: 'Maximum salary must be greater than or equal to minimum salary',
			},
		},
		jobOutlook: { type: String, required: true, enum: JOB_OUTLOOKS },
		industryOpportunities: [{ type: String, trim: true, maxlength: 200 }],

		pathway: [pathwayStepSchema],

		// --- Matching tags, consumed by the recommendation scoring service ---
		interestTags: [{ type: String, trim: true, lowercase: true, maxlength: 40 }],
		alSubjects: [{ type: String, trim: true, maxlength: 60 }],
		personalityTypes: [{ type: String, enum: PERSONALITY_TYPES }],
		workStyles: [{ type: String, enum: WORK_STYLES }],

		// Reference only. The Course module (Member 3) owns course data; the career
		// details screen uses these keywords to look courses up once that module
		// exists, and shows a placeholder until then.
		relatedCourseKeywords: [{ type: String, trim: true, lowercase: true, maxlength: 60 }],
	},
	{ timestamps: true, toJSON: { virtuals: true } },
);

// Keep pathway steps stored in the order they should be walked, so every screen
// can render them without sorting first.
// (Mongoose 9 middleware is synchronous/promise based -- it no longer takes next().)
careerSchema.pre('validate', function sortPathwaySteps() {
	if (Array.isArray(this.pathway)) this.pathway.sort((a, b) => a.order - b.order);
});

// Ready-to-display salary label, e.g. "LKR 180,000 - 550,000 / month".
careerSchema.virtual('salaryDisplay').get(function getSalaryDisplay() {
	if (!this.salaryRange) return '';
	const { min, max, currency, period } = this.salaryRange;
	const format = (value) => value.toLocaleString('en-LK');
	return `${currency} ${format(min)} - ${format(max)} / ${period}`;
});

module.exports = mongoose.model('Career', careerSchema);
