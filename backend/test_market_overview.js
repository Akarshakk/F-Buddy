const YahooFinance = require('yahoo-finance2').default;
const yahooFinance = new YahooFinance({ validation: { logErrors: false } });

(async () => {
    try {
        console.log('Fetching Market Overview Data...');

        // 1. Indices
        const indices = ['^NSEI', '^BSESN', '^GSPC'];
        console.log(`\nFetching Indices: ${indices.join(', ')}`);
        const indexQuotes = await yahooFinance.quote(indices);
        indexQuotes.forEach(q => {
            console.log(`${q.symbol}: ${q.regularMarketPrice} (${q.regularMarketChangePercent}%)`);
        });

        // 2. Daily Gainers (Yahoo defaults to US, checking if we can specify region)
        // Yahoo Finance query options for screener are complex, checking basic dailyGainers first
        try {
            console.log('\nFetching Daily Gainers (Default/US)...');
            const gainers = await yahooFinance.dailyGainers({ count: 5 });
            console.log(`Fetched ${gainers.quotes.length} gainers.`);
            gainers.quotes.slice(0, 3).forEach(q => console.log(`  ${q.symbol}: ${q.regularMarketChangePercent}%`));
        } catch (e) { console.log('Daily Gainers failed:', e.message); }

    } catch (error) {
        console.error('Error:', error);
    }
})();
