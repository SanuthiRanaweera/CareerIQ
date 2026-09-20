const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    sender: { type: String, enum: ['student', 'ai'], required: true },
    message: { type: String, required: true, trim: true, maxlength: 4000 },
    mode: { type: String, enum: ['career', 'course', 'interview', 'cv', 'roadmap', 'general'], default: 'general' },
  },
  { _id: true, timestamps: true },
);

const chatHistorySchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, unique: true, index: true },
    messages: { type: [messageSchema], default: [] },
  },
  { timestamps: true },
);

module.exports = mongoose.model('ChatHistory', chatHistorySchema);
