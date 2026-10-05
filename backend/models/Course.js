const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema(
	{
		title: { type: String, required: true, trim: true, maxlength: 160 },
		university: { type: String, required: true, trim: true, maxlength: 160 },
		stream: {
			type: String,
			required: true,
			trim: true,
			enum: ['Science', 'Mathematics', 'Commerce', 'Arts', 'Technology', 'Any'],
		},
		degreeType: { type: String, trim: true, maxlength: 80, default: "Bachelor's Degree" },
		description: { type: String, trim: true, maxlength: 3000, default: '' },
		durationYears: { type: Number, min: 0.5, max: 10, required: true },
		minZScore: { type: Number, min: -3, max: 5, default: null },
		subjects: [{ type: String, trim: true, maxlength: 80 }],
		careerPaths: [{ type: String, trim: true, maxlength: 100 }],
		website: { type: String, trim: true, maxlength: 300, default: '' },
		applicationUrl: { type: String, trim: true, maxlength: 300, default: '' },
		isActive: { type: Boolean, default: true, index: true },
	},
	{ timestamps: true },
);

courseSchema.index({ title: 'text', university: 'text', description: 'text' });
courseSchema.index({ stream: 1, university: 1, isActive: 1 });

module.exports = mongoose.model('Course', courseSchema);
