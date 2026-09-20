const ChatHistory = require('../models/ChatHistory');
const PersonalityTest = require('../models/PersonalityTest');
const Student = require('../models/Student');

const MAX_MESSAGE_LENGTH = 2000;
const MAX_HISTORY_MESSAGES = 20;
const supportedModes = new Set(['career', 'course', 'interview', 'cv', 'roadmap', 'general']);

function cleanMode(mode) {
  return supportedModes.has(mode) ? mode : 'general';
}

function formatStudentContext(student, personalityTest) {
  const results = student.alResults?.length
    ? student.alResults.map((result) => `${result.name}: ${result.grade}`).join(', ')
    : 'Not provided';
  const personality = personalityTest || student.personalityResult;
  const scores = personality?.scores
    ? Object.entries(personality.scores.toObject?.() || personality.scores)
        .map(([key, value]) => `${key}: ${value}`)
        .join(', ')
    : 'Not provided';

  return [
    `Name: ${student.fullName || 'Not provided'}`,
    `Age: ${student.dateOfBirth ? Math.floor((Date.now() - new Date(student.dateOfBirth).getTime()) / 31557600000) : 'Not provided'}`,
    `School: ${student.school || 'Not provided'}`,
    `District: ${student.district || 'Not provided'}`,
    `A/L Stream: ${student.stream || 'Not provided'}`,
    `A/L Results: ${results}`,
    `Personality Type: ${personality?.resultType || personality?.category || 'Not completed'}`,
    `Personality Scores: ${scores}`,
    `Strengths: ${(personality?.strengths || []).join(', ') || 'Not provided'}`,
    `Interests: ${(student.interests || []).join(', ') || 'Not provided'}`,
  ].join('\n');
}

function modeGuidance(mode) {
  const guidance = {
    career: 'Prioritize suitable career options and explain why they fit the student.',
    course: 'Compare degree and course options, entry considerations, and relevant skills.',
    interview: 'Act as an interview coach with practice questions, feedback, and concise model answers.',
    cv: 'Give practical CV improvement advice and ask for missing details before inventing content.',
    roadmap: 'Create a realistic step-by-step learning and career pathway with milestones.',
    general: 'Answer education and career questions clearly and connect them to the student context when useful.',
  };
  return guidance[mode];
}

function buildSystemPrompt(student, personalityTest, mode) {
  return `You are CareerIQ AI Assistant, a professional career guidance counselor for a student-focused education technology platform.

Your responsibility is to help students make informed career and education decisions. Provide clear explanations about careers, university courses, skills, learning paths, and professional development. Use the student's academic information and personality information when available. Do not provide unrelated answers. Encourage the student to explore options and make decisions based on interests, evidence, and goals. Do not claim certainty about admissions, salaries, or job outcomes; recommend checking current official university and employer information. Do not diagnose mental health conditions or provide unsafe advice. If a question is outside career and education guidance, briefly explain the scope and redirect it.

Current advisor mode: ${mode}. ${modeGuidance(mode)}

Student profile:
${formatStudentContext(student, personalityTest)}

Keep responses concise, warm, structured, and actionable. Use short headings or bullets when they improve readability.`;
}

async function callGemini(messages) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    const error = new Error('Gemini AI is not configured on the backend.');
    error.statusCode = 503;
    throw error;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);
  try {
    const model = process.env.GEMINI_MODEL || 'gemini-1.5-flash';
    const endpoint = process.env.GEMINI_API_URL ||
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
    const response = await fetch(`${endpoint}?key=${encodeURIComponent(apiKey)}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: messages[0].content }] },
        contents: messages.slice(1).map((message) => ({
          role: message.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: message.content }],
        })),
        generationConfig: { temperature: 0.35, maxOutputTokens: 700 },
      }),
      signal: controller.signal,
    });
    const payload = await response.json();
    if (!response.ok) {
      const error = new Error(payload.error?.message || 'Gemini request failed');
      error.statusCode = response.status >= 400 && response.status < 500 ? 502 : 503;
      error.expose = true;
      throw error;
    }
    const answer = payload.candidates?.[0]?.content?.parts
      ?.map((part) => part.text || '')
      .join('')
      .trim();
    if (!answer) throw new Error('Gemini returned an empty response');
    return answer;
  } finally {
    clearTimeout(timeout);
  }
}

async function getStudentContext(userId) {
  const student = await Student.findOne({ userId });
  if (!student) {
    const error = new Error('Student profile not found');
    error.statusCode = 404;
    throw error;
  }
  const personalityTest = await PersonalityTest.findOne({ studentId: student._id }).lean();
  return { student, personalityTest };
}

async function sendMessage(userId, message, mode = 'general') {
  const normalizedMessage = String(message || '').trim();
  if (!normalizedMessage || normalizedMessage.length > MAX_MESSAGE_LENGTH) {
    const error = new Error(`Message must be between 1 and ${MAX_MESSAGE_LENGTH} characters`);
    error.statusCode = 400;
    throw error;
  }

  const normalizedMode = cleanMode(mode);
  const { student, personalityTest } = await getStudentContext(userId);
  const history = await ChatHistory.findOne({ studentId: student._id });
  const recentMessages = (history?.messages || []).slice(-MAX_HISTORY_MESSAGES).map((item) => ({
    role: item.sender === 'student' ? 'user' : 'assistant',
    content: item.message,
  }));
  const aiMessage = await callGemini([
    { role: 'system', content: buildSystemPrompt(student, personalityTest, normalizedMode) },
    ...recentMessages,
    { role: 'user', content: normalizedMessage },
  ]);

  const updatedHistory = await ChatHistory.findOneAndUpdate(
    { studentId: student._id },
    {
      $push: {
        messages: {
          $each: [
            { sender: 'student', message: normalizedMessage, mode: normalizedMode },
            { sender: 'ai', message: aiMessage, mode: normalizedMode },
          ],
          $slice: -100,
        },
      },
    },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  );

  return { message: aiMessage, mode: normalizedMode, history: updatedHistory.messages };
}

async function getHistory(userId) {
  const { student } = await getStudentContext(userId);
  const history = await ChatHistory.findOne({ studentId: student._id }).lean();
  return (history?.messages || []).filter(
    (message) => !message.message.startsWith('CareerIQ AI is not configured yet.'),
  );
}

module.exports = { sendMessage, getHistory, MAX_MESSAGE_LENGTH };
