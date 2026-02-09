const express = require('express');
const router = express.Router();
const { chat, executeAction } = require('../controllers/chatController');
const { protect } = require('../middleware/auth');

// @route   POST /api/chat
// @desc    Process chat query with Gemini
// @access  Private
router.post('/', protect, chat);

// @route   POST /api/chat/execute
// @desc    Execute confirmed action
// @access  Private
router.post('/execute', protect, executeAction);

module.exports = router;
