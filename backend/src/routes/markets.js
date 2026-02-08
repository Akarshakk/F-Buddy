const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { handleValidationErrors } = require('../middleware/validate');
const { protect } = require('../middleware/auth');
const {
  getStocks,
  getStockDetail,
  searchStocks,
  getPortfolio,
  executeTrade,
  getTradeHistory,
  resetPortfolio,
  getMarketOverview,
  getWatchlist,
  addToWatchlist,
  removeFromWatchlist,
  checkWatchlist,
  compareStocks,
  getCandlestickData
} = require('../controllers/marketsController');
const { getBars, getSymbolInfo, searchSymbols } = require('../controllers/chartController');
const { getStream } = require('../controllers/chartController');

// Trade validation rules
const tradeValidation = [
  body('symbol')
    .notEmpty()
    .withMessage('Stock symbol is required')
    .isString()
    .withMessage('Symbol must be a string'),
  body('type')
    .notEmpty()
    .withMessage('Trade type is required')
    .isIn(['BUY', 'SELL', 'buy', 'sell'])
    .withMessage('Type must be BUY or SELL'),
  body('quantity')
    .notEmpty()
    .withMessage('Quantity is required')
    .isInt({ min: 1 })
    .withMessage('Quantity must be a positive integer')
];

// Watchlist validation
const watchlistValidation = [
  body('symbol')
    .notEmpty()
    .withMessage('Stock symbol is required')
];

// PUBLIC ROUTES (no authentication required)
// TradingView Datafeed API - Yahoo Finance only, stateless, no trading
router.get('/chart/bars', getBars);
router.get('/chart/symbol-info', getSymbolInfo);
router.get('/chart/search', searchSymbols);
router.get('/chart/stream', getStream);

// Temporary Public for Debugging
router.get('/stocks', getStocks);
router.get('/overview', getMarketOverview);

// Protected routes (authentication required)
router.use(protect);

// Market overview
// router.get('/overview', getMarketOverview);

// Stock routes
// router.get('/stocks', getStocks);
router.get('/stocks/:symbol', getStockDetail);
router.get('/search', searchStocks);

// Portfolio routes
router.get('/portfolio', getPortfolio);
router.post('/portfolio/reset', resetPortfolio);

// Trade routes
router.post('/trade', tradeValidation, handleValidationErrors, executeTrade);
router.get('/trades', getTradeHistory);

// Watchlist routes
router.get('/watchlist', getWatchlist);
router.post('/watchlist/add', watchlistValidation, handleValidationErrors, addToWatchlist);
router.delete('/watchlist/:symbol', removeFromWatchlist);
router.get('/watchlist/check/:symbol', checkWatchlist);

// Stock comparator route
router.post('/compare', compareStocks);

// Candlestick/OHLC data route
router.get('/stocks/:symbol/candles', getCandlestickData);

module.exports = router;
