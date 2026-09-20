const mongoose = require('mongoose');

const answeredQuestionSchema = new mongoose.Schema(
	{
		questionId: { type: String, required: true },
		answer: { type: String, required: true },
		score: { type: Number, required: true },
	},
	{ _id: false },
);

const categoryScoreSchema = new mongoose.Schema(
	{
		analytical: { type: Number, default: 0, min: 0, max: 100 },
		creative: { type: Number, default: 0, min: 0, max: 100 },
		social: { type: Number, default: 0, min: 0, max: 100 },
		leadership: { type: Number, default: 0, min: 0, max: 100 },
		practical: { type: Number, default: 0, min: 0, max: 100 },
		organized: { type: Number, default: 0, min: 0, max: 100 },
	},
	{ _id: false },
);

const personalityTestSchema = new mongoose.Schema(
	{
		studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, unique: true, index: true },
		questions: [answeredQuestionSchema],
		scores: { type: categoryScoreSchema, default: () => ({}) },
		resultType: { type: String, required: true, trim: true },
		strengths: [{ type: String, trim: true }],
		careers: [{ type: String, trim: true }],
		completedDate: { type: Date, default: Date.now },
	},
	{ timestamps: true },
);

module.exports = mongoose.model('PersonalityTest', personalityTestSchema);
