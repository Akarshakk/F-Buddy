/**
 * TradingView Datafeed API implementation
 * ---------------------------------------
 * Data source: backend chart API (Yahoo Finance). Chart rendering: TradingView only.
 * No trading, no order placement. Real-time simulated via polling (5–10 s).
 *
 * Assumptions:
 * - CHART_API_BASE is set globally (e.g. in chart.html) to backend base, e.g. 'http://localhost:5001/api/markets'
 * - Backend returns bars in format { time, open, high, low, close, volume } (time = Unix seconds).
 * Limitations: Polling is simulated live; not exchange-grade. For prototype/demo only.
 */

(function (global) {
  'use strict';

  var API_BASE = global.CHART_API_BASE || '';
  var POLL_INTERVAL_MS = 8000; // 8 seconds - simulate real-time
  var subscriptions = {}; // listenerGuid -> { intervalId, symbolInfo, resolution }

  function asyncRun(callback) {
    if (typeof setTimeout !== 'undefined') {
      setTimeout(callback, 0);
    } else {
      callback();
    }
  }

  function fetchBars(symbol, resolution, from, to) {
    var url = API_BASE + '/chart/bars?symbol=' + encodeURIComponent(symbol) +
      '&resolution=' + encodeURIComponent(resolution) +
      '&from=' + from + '&to=' + to;
    return fetch(url).then(function (res) { return res.json(); });
  }

  function fetchSymbolInfo(symbol) {
    var url = API_BASE + '/chart/symbol-info?symbol=' + encodeURIComponent(symbol);
    return fetch(url).then(function (res) { return res.json(); });
  }

  /**
   * TradingView calls this first. Return config with supported resolutions and features.
   */
  function onReady(callback) {
    asyncRun(function () {
      callback({
        supported_resolutions: ['1', '5', '15', '30', '60', '1D', '1W', '1M'],
        exchanges: [{ value: 'NSE', name: 'NSE', desc: 'National Stock Exchange' }],
        symbols_types: [{ value: 'stock', name: 'Stock' }],
        supported_resolutions: ['1', '5', '15', '30', '60', '1D', '1W', '1M'],
        supports_marks: false,
        supports_timescale_marks: false,
        supports_time: true
      });
    });
  }

  /**
   * Resolve symbol name to SymbolInfo for the chart.
   */
  function resolveSymbol(symbolName, onResolve, onError) {
    asyncRun(function () {
      fetchSymbolInfo(symbolName)
        .then(function (json) {
          if (!json.success || !json.data) {
            onError('Symbol not found: ' + symbolName);
            return;
          }
          var d = json.data;
          var symbolInfo = {
            ticker: d.ticker || symbolName,
            name: d.name || symbolName,
            description: d.description || d.name || symbolName,
            type: 'stock',
            session: '0900-1530',
            timezone: 'Asia/Kolkata',
            exchange: d.exchange || 'NSE',
            minmov: 1,
            pricescale: 100,
            has_intraday: true,
            has_weekly_and_daily: true,
            supported_resolutions: ['1', '5', '15', '30', '60', '1D', '1W', '1M'],
            volume_precision: 0,
            data_status: 'streaming'
          };
          onResolve(symbolInfo);
        })
        .catch(function (err) {
          onError(err.message || 'Failed to resolve symbol');
        });
    });
  }

  /**
   * Core: fetch historical bars for the given range. TradingView expects time in Unix seconds.
   */
  function getBars(symbolInfo, resolution, periodParams, onResult, onError) {
    var symbol = symbolInfo.ticker || symbolInfo.name;
    var from = periodParams.from;
    var to = periodParams.to;

    asyncRun(function () {
      fetchBars(symbol, resolution, from, to)
        .then(function (json) {
          if (!json.success) {
            onError(json.message || 'Failed to load bars');
            return;
          }
          var bars = json.data || [];
          var meta = bars.length === 0 ? { noData: true } : {};
          onResult(bars, meta);
        })
        .catch(function (err) {
          onError(err.message || 'Network error');
        });
    });
  }

  /**
   * Subscribe to real-time updates. We simulate by polling every POLL_INTERVAL_MS
   * and sending the latest bar (or current quote) as a new bar.
   */
  function subscribeBars(symbolInfo, resolution, onTick, listenerGuid) {
    var symbol = symbolInfo.ticker || symbolInfo.name;
    var to = Math.floor(Date.now() / 1000);
    var from = to - (resolution === '1' || resolution === '5' ? 86400 * 2 : 86400 * 30);

    function poll() {
      fetchBars(symbol, resolution, from, to)
        .then(function (json) {
          if (!json.success || !json.data || json.data.length === 0) return;
          var bars = json.data;
          var last = bars[bars.length - 1];
          onTick(last);
        })
        .catch(function () {});
    }

    poll();
    var intervalId = setInterval(poll, POLL_INTERVAL_MS);
    subscriptions[listenerGuid] = { intervalId: intervalId, symbolInfo: symbolInfo, resolution: resolution };
  }

  function unsubscribeBars(listenerGuid) {
    var sub = subscriptions[listenerGuid];
    if (sub && sub.intervalId) {
      clearInterval(sub.intervalId);
    }
    delete subscriptions[listenerGuid];
  }

  var Datafeed = {
    onReady: onReady,
    resolveSymbol: resolveSymbol,
    getBars: getBars,
    subscribeBars: subscribeBars,
    unsubscribeBars: unsubscribeBars
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = Datafeed;
  } else {
    global.TradingViewDatafeed = Datafeed;
  }
})(typeof window !== 'undefined' ? window : this);
