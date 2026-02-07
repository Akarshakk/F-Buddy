const express = require('express');
const router = express.Router();
const marketController = require('../controllers/marketController');

// Configuration
router.get('/config', marketController.getConfig);

// Symbol Information
router.get('/symbol-info', marketController.getSymbolInfo);

// Symbol Search
router.get('/search', marketController.searchSymbols);

// Historical Data
router.get('/history', marketController.getHistory);

module.exports = router;
