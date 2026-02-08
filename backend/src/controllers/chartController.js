/**
 * Chart API Controller (TradingView Datafeed backend)
 * ---------------------------------------------------
 * Thin, stateless endpoints for the TradingView Datafeed.
 * Data source: Yahoo Finance only (see yahooChartService).
 * No trading, no order placement, no broker integration.
 */

const yahooChartService = require('../services/yahooChartService');

/**
 * GET /api/markets/chart/bars
 * Query: symbol, resolution, from, to (all required; from/to = Unix seconds)
 * Returns: { success, data: [ { time, open, high, low, close, volume }, ... ] }
 */
exports.getBars = async (req, res) => {
  try {
    const { symbol, resolution, from, to } = req.query;
    if (!symbol || !resolution || from === undefined || to === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Missing required query params: symbol, resolution, from, to (Unix seconds)'
      });
    }
    const fromSec = parseInt(from, 10);
    const toSec = parseInt(to, 10);
    if (isNaN(fromSec) || isNaN(toSec) || fromSec >= toSec) {
      return res.status(400).json({
        success: false,
        message: 'Invalid from/to: must be Unix seconds with from < to'
      });
    }

    const bars = await yahooChartService.getBars(symbol, resolution, fromSec, toSec);
    res.status(200).json({
      success: true,
      data: bars
    });
  } catch (error) {
    console.error('[Chart] getBars error:', error.message);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch bars'
    });
  }
};

/**
 * GET /api/markets/chart/symbol-info
 * Query: symbol (required)
 * Returns: { success, data: { ticker, name, exchange, description } }
 * Used by Datafeed resolveSymbol.
 */
exports.getSymbolInfo = async (req, res) => {
  try {
    const { symbol } = req.query;
    if (!symbol) {
      return res.status(400).json({
        success: false,
        message: 'Missing query param: symbol'
      });
    }
    const info = await yahooChartService.resolveSymbol(symbol);
    res.status(200).json({
      success: true,
      data: info
    });
  } catch (error) {
    console.error('[Chart] getSymbolInfo error:', error.message);
    res.status(404).json({
      success: false,
      message: error.message || 'Symbol not found'
    });
  }
};

/**
 * GET /api/markets/chart/search
 * Query: q (required, min 2 chars)
 * Returns: { success, data: [ { symbol, name }, ... ] }
 */
exports.searchSymbols = async (req, res) => {
  try {
    const q = (req.query.q || '').trim();
    if (q.length < 2) {
      return res.status(200).json({ success: true, data: [] });
    }
    const results = await yahooChartService.searchSymbols(q);
    res.status(200).json({
      success: true,
      data: results
    });
  } catch (error) {
    console.error('[Chart] search error:', error.message);
    res.status(500).json({
      success: false,
      message: error.message || 'Search failed'
    });
  }
};

/**
 * GET /api/markets/chart/stream
 * Query: symbol, resolution, pollInterval (seconds, optional default 5)
 * Returns Server-Sent Events stream of latest bars for the symbol.
 * Lightweight: each client connection polls Yahoo and streams updates; no global state.
 */
exports.getStream = async (req, res) => {
  const { symbol, resolution = 'D', pollInterval = '5' } = req.query;
  if (!symbol) return res.status(400).json({ success: false, message: 'Missing symbol' });

  // SSE headers
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    Connection: 'keep-alive'
  });

  let closed = false;
  req.on('close', () => { closed = true; });

  const yahooService = require('../services/yahooChartService');
  const intervalMs = Math.max(1000, parseInt(pollInterval, 10) * 1000);

  // Helper: send SSE event
  const sendEvent = (data) => {
    try {
      res.write(`data: ${JSON.stringify(data)}\n\n`);
    } catch (e) {
      // ignore
    }
  };

  // Poll loop
  (async () => {
    let lastTs = 0;
    while (!closed) {
      try {
        const to = Math.floor(Date.now() / 1000);
        const from = to - 60 * 60; // last 1 hour window for intraday
        const bars = await yahooService.getBars(symbol, resolution, from, to);
        if (Array.isArray(bars) && bars.length) {
          const newest = bars[bars.length - 1];
          if (!lastTs || newest.time > lastTs) {
            lastTs = newest.time;
            sendEvent({ symbol, bar: newest });
          }
        }
      } catch (err) {
        sendEvent({ error: err.message });
      }
      await new Promise(r => setTimeout(r, intervalMs));
    }
    try { res.end(); } catch (_) {}
  })();
};
