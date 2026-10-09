require('dotenv').config({ path: require('path').join(__dirname, '.env') });

const express = require('express');
const cors = require('cors');
const { connectDatabase, getDatabaseStatus } = require('./config/database');
const authRoutes = require('./routes/authRoutes');
const studentRoutes = require('./routes/studentRoutes');
const universityRoutes = require('./routes/universityRoutes');
const personalityRoutes = require('./routes/personalityRoutes');
const chatbotRoutes = require('./routes/chatbotRoutes');
const careerRoutes = require('./routes/careerRoutes');
const courseRoutes = require('./routes/courseRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const groupChatRoutes = require('./routes/groupChatRoutes');
const scholarshipRoutes = require('./routes/scholarshipRoutes');
const universityScholarshipRoutes = require('./routes/universityScholarshipRoutes');
const universityApplicationRoutes = require('./routes/universityApplicationRoutes');
const studentScholarshipRoutes = require('./routes/studentScholarshipRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const errorHandler = require('./middleware/errorMiddleware');

const app = express();
const port = Number(process.env.PORT) || 3000;

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'CareerIQ API',
    database: getDatabaseStatus(),
    timestamp: new Date().toISOString(),
  });
});

app.use('/api', (_req, res, next) => {
  if (getDatabaseStatus() !== 'connected') {
    return res.status(503).json({
      success: false,
      message: 'Database unavailable. Please try again shortly.',
    });
  }
  next();
});

app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/student', studentRoutes);
// Specific university sub-routes must be mounted before generic /api/university
app.use('/api/university/scholarships', universityScholarshipRoutes);
app.use('/api/university/applications', universityApplicationRoutes);
app.use('/api/universities', universityRoutes);
app.use('/api/university', universityRoutes);
app.get('/api/admin/university-statistics', require('./middleware/authMiddleware').protect, require('./middleware/adminMiddleware').adminOnly, require('./controllers/universityController').getUniversityStatistics);
app.use('/api/personality', personalityRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/careers', careerRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/group-chat', groupChatRoutes);

// Scholarship routes
app.use('/api/scholarships', scholarshipRoutes);
app.use('/api/student/scholarship-applications', studentScholarshipRoutes);
app.get('/api/admin/scholarships', require('./middleware/authMiddleware').protect, require('./middleware/adminMiddleware').adminOnly, require('./controllers/scholarshipController').listAdminScholarships);

// Analytics routes
app.use('/api/analytics', analyticsRoutes);


app.use((_req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

app.use(errorHandler);

let databaseRetryTimer;

async function connectWithRetry() {
  try {
    await connectDatabase();
    if (databaseRetryTimer) {
      clearInterval(databaseRetryTimer);
      databaseRetryTimer = undefined;
    }
  } catch (error) {
    console.error(`MongoDB unavailable; retrying in 15 seconds: ${error.message}`);
    if (!databaseRetryTimer) databaseRetryTimer = setInterval(connectWithRetry, 15000);
  }
}

app.listen(port, '0.0.0.0', () => {
  console.log(`CareerIQ API listening on port ${port}`);
  connectWithRetry();
});