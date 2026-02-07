# Chart API (Yahoo Finance + TradingView Datafeed)

Thin, stateless endpoints for the TradingView Datafeed. **Data source: Yahoo Finance only** (code-based, no API key). No trading, no order placement.

## Architecture

- **Data source**: Yahoo Finance (via `yahoo-finance2` in `src/services/yahooChartService.js`).
- **Chart rendering**: TradingView Charting Library (frontend); this backend only serves data.
- **Datafeed**: Implemented in `mobile/web/tv/datafeed.js`; it calls the endpoints below.

You can later swap Yahoo for NSE/licensed feeds by replacing `yahooChartService` and keeping the same API contract.

## Endpoints (public, no auth)

Base path: `/api/markets` (mount point).

| Method | Path | Query | Description |
|--------|------|--------|-------------|
| GET | `/chart/bars` | `symbol`, `resolution`, `from`, `to` (all required) | OHLCV bars. `from`/`to` = Unix seconds. |
| GET | `/chart/symbol-info` | `symbol` | Resolve symbol to name, exchange, etc. (for Datafeed `resolveSymbol`). |
| GET | `/chart/search` | `q` (min 2 chars) | Symbol search (for UI symbol search). |

### Bar format

Each bar: `{ time, open, high, low, close, volume }`.

- `time`: Unix timestamp in **seconds** (TradingView convention).
- `open`, `high`, `low`, `close`: numbers.
- `volume`: integer.

### Resolutions

Supported `resolution` values: `1`, `5`, `15`, `30`, `60` (minutes), `1D`, `1W`, `1M`. Mapped to Yahoo intervals: `1m`, `5m`, `15m`, `30m`, `1h`, `1d`, `1wk`, `1mo`.

### Example

```bash
# Bars for RELIANCE.NS, daily, last 30 days
curl "http://localhost:5001/api/markets/chart/bars?symbol=RELIANCE.NS&resolution=1D&from=1735689600&to=1738281600"
```

## Limitations (demo / hackathon)

- Yahoo Finance is unofficial; no guarantees on rate limits or availability.
- Real-time in the Datafeed is simulated via polling (e.g. every 8 s), not true streaming.
- For production trading, use licensed NSE/feed and proper real-time data.
