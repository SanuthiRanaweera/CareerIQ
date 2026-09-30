require('dotenv').config({ path: require('path').join(__dirname, '.env') });

const express = require('express');
const cors = require('cors');
const { connectDatabase, getDatabaseStatus } = require('./config/database');
const authRoutes = require('./routes/authRoutes');
const studentRoutes = require('./routes/studentRoutes');
const personalityRoutes = require('./routes/personalityRoutes');
const chatbotRoutes = require('./routes/chatbotRoutes');
const careerRoutes = require('./routes/careerRoutes');
const errorHandler = require('./middleware/errorMiddleware');

const app = express();
const port = Number(process.env.PORT) || 3000;

app.use(cors());
app.use(express.json());

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
app.use('/api/personality', personalityRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/careers', careerRoutes);

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