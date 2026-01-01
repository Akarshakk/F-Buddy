const express = require('express');
const router = express.Router();
const multer = require('multer');
const { protect } = require('../middleware/auth');
const { processBill, processBillBase64 } = require('../controllers/billController');

// Configure multer for memory storage (for image uploads)
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept only image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// POST /api/bill/scan - Upload and process bill image
router.post('/scan', protect, upload.single('bill'), processBill);

// POST /api/bill/scan-base64 - Process bill from base64 string
router.post('/scan-base64', protect, processBillBase64);

module.exports = router;
