# TradingView Datafeed (Yahoo Finance)

This folder contains the **TradingView Datafeed API** implementation used by the chart page. Data comes from your backend, which uses **Yahoo Finance** (code-based, no API key). Chart rendering is done by **TradingView Charting Library** only.

## Architecture

- **Data source**: Yahoo Finance (via backend `yahooChartService` → `/api/markets/chart/*`).
- **Chart rendering**: TradingView Charting Library (you add the library; see below).
- **Datafeed** (`datafeed.js`): Implements TradingView’s Datafeed interface and calls the backend. No trading, no order placement.

## Datafeed API methods

| Method | Purpose |
|--------|--------|
| `onReady(callback)` | Called first; returns supported resolutions and config. |
| `resolveSymbol(symbolName, onResolve, onError)` | Resolves symbol to SymbolInfo (name, exchange, etc.). |
| `getBars(symbolInfo, resolution, periodParams, onResult, onError)` | Fetches OHLCV bars for the requested range (core logic). |
| `subscribeBars(..., onTick, listenerGuid)` | Simulates real-time by polling backend every ~8 s. |
| `unsubscribeBars(listenerGuid)` | Stops polling for that subscription. |

Bar format: `{ time, open, high, low, close, volume }` with `time` in **Unix seconds**.

## Backend base URL

Set `CHART_API_BASE` before loading the datafeed (e.g. in `chart.html`). Example: `http://localhost:5001/api/markets`. The chart page can override it via query: `?api=http://your-backend:5001`.

## Adding the TradingView Charting Library

1. Get the free Charting Library from [TradingView Charting Library](https://www.tradingview.com/charting-library-docs/).
2. Extract it so that `charting_library.standalone.js` (or equivalent) is at `web/charting_library/` (next to `chart.html`).
3. In `chart.html`, uncomment the script that loads the library and the widget initialization.

Without the library, `chart.html` shows instructions only; the Datafeed and backend are still usable once the library is added.

## Limitations (hackathon / demo)

- Real-time is simulated via polling (e.g. every 8 s), not true streaming.
- Yahoo Finance is unofficial; rate limits and availability are not guaranteed.
- For production trading you would replace Yahoo with licensed NSE/feed and proper real-time data.
