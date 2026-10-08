const mongoose = require('mongoose');

const answerOptionSchema = new mongoose.Schema(
  {
    text: { type: String, required: true, trim: true },
    score: { type: Number, required: true },
  },
  { _id: false },
);

const personalityQuestionSchema = new mongoose.Schema(
  {
    questionText: { type: String, required: true, trim: true },
    type: {
      type: String,
      required: true,
      enum: ['personality', 'interest', 'skills', 'work_style'],
      default: 'personality',
      index: true,
    },
    category: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
      index: true,
    },
    answerType: {
      type: String,
      enum: ['likert', 'multiple_choice'],
      default: 'likert',
    },
    options: {
      type: [answerOptionSchema],
      default: [
        { text: 'Strongly Agree', score: 5 },
        { text: 'Agree', score: 4 },
        { text: 'Neutral', score: 3 },
        { text: 'Disagree', score: 2 },
        { text: 'Strongly Disagree', score: 1 },
      ],
      validate: {
        validator: (opts) => Array.isArray(opts) && opts.length >= 2,
        message: 'Question must have at least 2 options',
      },
    },
    reverseScoring: { type: Boolean, default: false },
    displayOrder: { type: Number, default: 1, index: true },
    isActive: { type: Boolean, default: true, index: true },
  },
  { timestamps: true },
);

// Virtual for backward-compatible `text` field
personalityQuestionSchema.virtual('text').get(function () {
  return this.questionText;
});

personalityQuestionSchema.set('toJSON', { virtuals: true });
personalityQuestionSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('PersonalityQuestion', personalityQuestionSchema);

