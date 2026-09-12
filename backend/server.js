require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { connectDatabase, getDatabaseStatus } = require('./config/database');
const authRoutes = require('./routes/authRoutes');
const studentRoutes = require('./routes/studentRoutes');
const errorHandler = require('./middleware/errorMiddleware');

const app = express();
const port = Number(process.env.PORT) || 3000;

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);

app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'CareerIQ API',
    database: getDatabaseStatus(),
    timestamp: new Date().toISOString(),
  });
});

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