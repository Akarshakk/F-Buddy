/**
 * Yahoo Chart Service
 * -------------------
 * Uses `yahoo-finance2` as a thin, stateless data source for OHLCV data.
 * - No HTML scraping
 * - No paid APIs
 * - Data is normalized to TradingView candle format: { time, open, high, low, close, volume }
 *
 * Assumptions & limitations:
 * - Intervals are best-effort mappings between TradingView resolutions and Yahoo intervals.
 * - Intraday data (1m/5m/15m/30m/60m) may be limited by Yahoo availability.
 * - This service is for prototype/demo use only; not production-grade.
 */

const yahoo = require('yahoo-finance2').default;

const resolutionToInterval = (resolution) => {
  // TradingView resolution examples: '1','5','15','30','60','D','W','M'
  const r = String(resolution).toUpperCase();
  if (r === '1') return '1m';
  if (r === '5') return '5m';
  if (r === '15') return '15m';
  if (r === '30') return '30m';
  if (r === '60' || r === '1H') return '60m';
  if (r === 'D' || r === '1D') return '1d';
  if (r === 'W') return '1wk';
  if (r === 'M') return '1mo';
  // default to daily
  return '1d';
};

const normalizeChart = (chart, timezoneOffset = 0) => {
  // chart: result from yahoo.chart()
  // We expect chart.result[0].timestamp and indicators.quote[0] arrays.
  if (!chart || !chart.result || !chart.result[0]) return [];
  const r = chart.result[0];
  const timestamps = r.timestamp || [];
  const quotes = (r.indicators && r.indicators.quote && r.indicators.quote[0]) || {};
  const opens = quotes.open || [];
  const highs = quotes.high || [];
  const lows = quotes.low || [];
  const closes = quotes.close || [];
  const volumes = quotes.volume || [];

  const bars = [];
  for (let i = 0; i < timestamps.length; i++) {
    const ts = timestamps[i] * 1000; // yahoo gives seconds
    bars.push({
      time: ts, // ms epoch as TradingView expects (ms ok)
      open: opens[i] != null ? parseFloat(opens[i]) : null,
      high: highs[i] != null ? parseFloat(highs[i]) : null,
      low: lows[i] != null ? parseFloat(lows[i]) : null,
      close: closes[i] != null ? parseFloat(closes[i]) : null,
      volume: volumes[i] != null ? parseInt(volumes[i], 10) : 0
    });
  }
  return bars;
};

exports.getBars = async (symbol, resolution, fromSec, toSec) => {
  const interval = resolutionToInterval(resolution);
  const period1 = new Date(fromSec * 1000);
  const period2 = new Date(toSec * 1000);

  // yahoo-finance2 chart options
  const opts = { period1, period2, interval, includePrePost: false };
  try {
    const chart = await yahoo.chart(symbol, opts);
    const bars = normalizeChart(chart);
    // Ensure oldest-first order (TradingView expects ascending time)
    return bars.sort((a, b) => a.time - b.time);
  } catch (err) {
    // Bubble up error with friendly message
    throw new Error(`Yahoo chart fetch failed for ${symbol}: ${err.message}`);
  }
};

exports.resolveSymbol = async (symbol) => {
  try {
    // Use quoteSummary to get name and exchange
    const q = await yahoo.quoteSummary(symbol, { modules: ['price', 'summaryProfile'] });
    const price = q.price || {};
    return {
      ticker: symbol.toUpperCase(),
      name: price.longName || price.shortName || symbol,
      exchange: price.exchangeName || price.fullExchangeName || 'YAHOO',
      description: q.summaryProfile?.longBusinessSummary || ''
    };
  } catch (err) {
    throw new Error(`Symbol resolve failed: ${err.message}`);
  }
};

exports.searchSymbols = async (query) => {
  try {
    const res = await yahoo.search(query);
    if (!res || !res.quotes) return [];
    // Map to { symbol, name }
    return res.quotes.slice(0, 20).map(q => ({ symbol: q.symbol, name: q.shortname || q.longname || q.exchDisp || q.symbol }));
  } catch (err) {
    console.error('[Yahoo] search failed:', err.message);
    return [];
  }
};
/**
 * Yahoo Finance Chart Data Service
 * ---------------------------------
 * Data-source layer only. Fetches OHLCV from Yahoo Finance (code-based, no API key)
 * and normalizes to TradingView bar format: { time, open, high, low, close, volume }.
 * Stateless; no caching. Can be swapped later for NSE/licensed feeds.
 *
 * Assumptions:
 * - Yahoo symbol format: NSE = RELIANCE.NS, BSE = RELIANCE.BO (we use .NS by default).
 * - Time in TradingView format: Unix seconds (UTC).
 * Limitations: Unofficial API; rate limits and availability not guaranteed. Demo use only.
 */

const YahooFinance = require('yahoo-finance2').default;
const yahooFinance = new YahooFinance();

// Map TradingView resolution string to Yahoo Finance interval
const RESOLUTION_TO_INTERVAL = {
  '1': '1m',
  '5': '5m',
  '15': '15m',
  '30': '30m',
  '60': '1h',
  '1D': '1d',
  '1W': '1wk',
  '1M': '1mo'
};

/**
 * Fetch OHLCV bars from Yahoo Finance and normalize to TradingView format.
 * @param {string} symbol - Yahoo symbol (e.g. RELIANCE.NS, AAPL)
 * @param {string} resolution - TradingView resolution: 1, 5, 15, 30, 60, 1D, 1W, 1M
 * @param {number} from - Unix seconds (inclusive)
 * @param {number} to - Unix seconds (inclusive)
 * @returns {Promise<Array<{ time: number, open: number, high: number, low: number, close: number, volume: number }>>}
 */
async function getBars(symbol, resolution, from, to) {
  const interval = RESOLUTION_TO_INTERVAL[resolution] || '1d';
  const period1 = new Date(from * 1000);
  const period2 = new Date(to * 1000);

  const result = await yahooFinance.chart(symbol, {
    period1,
    period2,
    interval
  });

  if (!result.quotes || result.quotes.length === 0) {
    return [];
  }

  // Normalize to TradingView format: time in Unix seconds
  return result.quotes
    .filter(q => q.open != null && q.high != null && q.low != null && q.close != null)
    .map(q => ({
      time: Math.floor(q.date.getTime() / 1000),
      open: round(q.open),
      high: round(q.high),
      low: round(q.low),
      close: round(q.close),
      volume: q.volume != null ? Math.floor(Number(q.volume)) : 0
    }))
    .sort((a, b) => a.time - b.time);
}

/**
 * Resolve symbol to minimal info for TradingView (name, exchange, etc.).
 * @param {string} symbol - Yahoo symbol
 * @returns {Promise<{ ticker: string, name: string, exchange?: string, description?: string }>}
 */
async function resolveSymbol(symbol) {
  const quote = await yahooFinance.quote(symbol);
  if (!quote) {
    throw new Error(`Symbol not found: ${symbol}`);
  }
  return {
    ticker: symbol,
    name: quote.shortName || quote.longName || symbol,
    exchange: quote.exchange || 'NSE',
    description: quote.longName || quote.shortName || symbol
  };
}

/**
 * Search symbols by query (for symbol search in UI).
 * @param {string} query
 * @returns {Promise<Array<{ symbol: string, name: string }>>}
 */
async function searchSymbols(query) {
  if (!query || query.length < 2) return [];
  const results = await yahooFinance.search(query);
  const quotes = results.quotes || [];
  return quotes
    .filter(q => q.symbol && (q.quoteType === 'EQUITY' || q.quoteType === 'ETF' || q.quoteType === 'INDEX'))
    .slice(0, 30)
    .map(q => ({
      symbol: q.symbol,
      name: q.shortname || q.longname || q.symbol
    }));
}

function round(n) {
  return Math.round(Number(n) * 100) / 100;
}

module.exports = {
  getBars,
  resolveSymbol,
  searchSymbols
};
