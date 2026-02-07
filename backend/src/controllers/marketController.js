const yahooFinance = require('../config/yahooFinance');
// const YahooFinance = require('yahoo-finance2').default; // Removed
// const yahooFinance = new YahooFinance(); // Removed

/**
 * Get TradingView Configuration
 * Returns supported resolutions and exchanges
 */
exports.getConfig = (req, res) => {
    res.json({
        supported_resolutions: ['1', '5', '15', '30', '60', 'D', 'W', 'M'],
        supports_group_request: false,
        supports_marks: false,
        supports_search: true,
        supports_timescale_marks: false,
        exchanges: [
            {
                value: 'NSE',
                name: 'NSE',
                desc: 'National Stock Exchange of India'
            },
            {
                value: 'BSE',
                name: 'BSE',
                desc: 'Bombay Stock Exchange'
            },
            {
                value: 'NASDAQ',
                name: 'NASDAQ',
                desc: 'NASDAQ'
            },
            {
                value: 'NYSE',
                name: 'NYSE',
                desc: 'New York Stock Exchange'
            }
        ],
        symbols_types: [
            {
                name: 'Stock',
                value: 'stock'
            },
            {
                name: 'Index',
                value: 'index'
            }
        ]
    });
};

/**
 * Get Symbol Information
 * Returns metadata for a specific symbol
 */
exports.getSymbolInfo = async (req, res) => {
    const symbol = req.query.symbol;

    if (!symbol) {
        return res.status(400).json({ error: 'Symbol is required' });
    }

    try {
        // We can verify if the symbol exists using yahoo-finance2 quote
        // But for hackathon speed, we'll return a constructed object directly
        // based on the requested symbol to be faster/safer from rate limits.
        // Ideally, catch "Not Found" errors from quote() if strictly needed.

        // Attempt a quick quote fetch to get the real name/exchange if possible
        let quote = {};
        try {
            quote = await yahooFinance.quote(symbol);
        } catch (e) {
            console.log(`[MarketController] Quote fetch failed for ${symbol}: ${e.message}`);
            // Fallback to basic info if quote fails
            quote = {
                symbol: symbol,
                shortName: symbol,
                exchange: 'Unknown',
                currency: 'INR'
            };
        }

        res.json({
            name: quote.symbol || symbol,
            ticker: quote.symbol || symbol,
            description: quote.longName || quote.shortName || symbol,
            type: 'stock',
            session: '0915-1530', // Indian Market default
            timezone: 'Asia/Kolkata',
            exchange: quote.exchange || 'NSE',
            minmov: 1,
            pricescale: 100,
            has_intraday: true,
            has_no_volume: false,
            has_weekly_and_monthly: true,
            supported_resolutions: ['1', '5', '15', '30', '60', 'D', 'W', 'M'],
            volume_precision: 2,
            data_status: 'streaming',
        });
    } catch (error) {
        console.error('[MarketController] Symbol info error:', error);
        res.status(500).json({ error: 'Failed to fetch symbol info' });
    }
};

/**
 * Get Historical Data (Bars)
 * param: symbol, resolution, from, to
 */
exports.getHistory = async (req, res) => {
    const { symbol, resolution, from, to } = req.query;

    if (!symbol || !from || !to) {
        return res.status(400).json({ error: 'Missing required parameters' });
    }

    console.log(`[MarketController] Fetching history for ${symbol} (${resolution}) from ${from} to ${to}`);

    try {
        // Map TradingView resolution to Yahoo Finance interval
        let interval = '1d';
        if (resolution === '1') interval = '1m';
        else if (resolution === '5') interval = '5m';
        else if (resolution === '15') interval = '15m';
        else if (resolution === '30') interval = '30m';
        else if (resolution === '60') interval = '1h';
        else if (resolution === 'D') interval = '1d';
        else if (resolution === 'W') interval = '1wk';
        else if (resolution === 'M') interval = '1mo';

        // Convert seconds (TV) to Date objects (Yahoo)
        const period1 = new Date(parseInt(from) * 1000);
        const period2 = new Date(parseInt(to) * 1000);

        const queryOptions = {
            period1: from * 1000, // API expects ms timestamp, or date string
            period2: to * 1000,
            interval: interval,
            includePrePost: false
        };

        // Use chart() instead of historical()
        // Note: yahoo-finance2 chart() returns { meta, quotes: [...] }
        const result = await yahooFinance.chart(symbol, queryOptions);

        if (!result || !result.quotes || result.quotes.length === 0) {
            return res.json({ success: true, data: [] });
        }

        // Map to TradingView format
        // TV expects: { time, open, high, low, close, volume }
        const bars = result.quotes.map(quote => ({
            time: new Date(quote.date).getTime(), // Time in milliseconds
            open: quote.open,
            high: quote.high,
            low: quote.low,
            close: quote.close,
            volume: quote.volume
        }));

        res.json({
            success: true,
            data: bars
        });

    } catch (error) {
        console.error('[MarketController] History fetch error:', error);
        res.status(500).json({ error: error.message || 'Failed to fetch history' });
    }
};

/**
 * Search Symbols
 * Simple search functionality
 */
exports.searchSymbols = async (req, res) => {
    const query = req.query.query;
    if (!query) return res.json([]);

    try {
        const results = await yahooFinance.search(query);
        const symbols = results.quotes
            .filter(q => q.isYahooFinance === true && (q.quoteType === 'EQUITY' || q.quoteType === 'INDEX'))
            .map(q => ({
                symbol: q.symbol,
                full_name: q.symbol,
                description: q.longname || q.shortname || q.symbol,
                exchange: q.exchange,
                ticker: q.symbol,
                type: 'stock'
            }));
        res.json(symbols);
    } catch (error) {
        console.error('[MarketController] Search error:', error);
        res.json([]);
    }
};
