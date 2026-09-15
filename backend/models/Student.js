const mongoose = require('mongoose');

const subjectResultSchema = new mongoose.Schema(
	{
		name: { type: String, required: true, trim: true, maxlength: 80 },
		grade: { type: String, required: true, trim: true, maxlength: 10 },
	},
	{ _id: true },
);

const studentSchema = new mongoose.Schema(
	{
		userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
		fullName: { type: String, required: true, trim: true, maxlength: 100 },
		email: { type: String, required: true, lowercase: true, trim: true },
		dateOfBirth: { type: Date },
		school: { type: String, trim: true, maxlength: 150 },
		district: { type: String, trim: true, maxlength: 80 },
		alYear: { type: Number, min: 1900, max: 2200 },
		stream: { type: String, enum: ['Science', 'Mathematics', 'Commerce', 'Arts', 'Technology'] },
		profileImage: { type: String, trim: true },
		interests: [{ type: String, trim: true }],
		alResults: [subjectResultSchema],
		personalityResult: {
			category: { type: String, trim: true },
			strengths: [{ type: String, trim: true }],
			completedAt: { type: Date },
		},
		favoriteCareers: [{ type: mongoose.Schema.Types.ObjectId }],
		favoriteCourses: [{ type: mongoose.Schema.Types.ObjectId }],
	},
	{ timestamps: true, toJSON: { virtuals: true } },
);

studentSchema.virtual('profileCompletion').get(function getProfileCompletion() {
	const checks = [
		Boolean(this.fullName), Boolean(this.email), Boolean(this.school), Boolean(this.district),
		Boolean(this.alYear), Boolean(this.stream), this.alResults.length > 0,
		Boolean(this.personalityResult?.category),
	];
	return Math.round((checks.filter(Boolean).length / checks.length) * 100);
});

module.exports = mongoose.model('Student', studentSchema);
