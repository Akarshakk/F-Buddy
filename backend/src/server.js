require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { initializeFirebase } = require('./config/firebase');

// Import routes
const authRoutes = require('./routes/auth');
const incomeRoutes = require('./routes/income');
const expenseRoutes = require('./routes/expense');
const analyticsRoutes = require('./routes/analytics');
const categoryRoutes = require('./routes/category');
const billRoutes = require('./routes/bill');
const debtRoutes = require('./routes/debt');
const groupRoutes = require('./routes/group');

const app = express();

// Connect to Firebase
initializeFirebase();

// Middleware
app.use(cors({
  origin: '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(morgan('dev'));
app.use('/uploads', express.static('uploads'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/income', incomeRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/bill', billRoutes);
app.use('/api/debts', debtRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/kyc', require('./routes/kyc'));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'F Buddy API is running!' });
});

// Test auth endpoint
app.get('/api/test-auth', (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  res.json({
    success: true,
    message: 'Auth test endpoint',
    hasAuthHeader: !!req.headers.authorization,
    hasToken: !!token,
    token: token ? token.substring(0, 20) + '...' : null
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀 F Buddy Server running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV}`);
});

module.exports = app;
