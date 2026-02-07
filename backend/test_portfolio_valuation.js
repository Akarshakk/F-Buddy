const YahooFinance = require('yahoo-finance2').default;
const yahooFinance = new YahooFinance({ validation: { logErrors: false } });

(async () => {
    try {
        const symbols = ['AAPL', 'RELIANCE.NS', 'TCS.NS', 'INVALID_SYM'];
        console.log(`Fetching quotes for: ${symbols.join(', ')}`);

        const quotes = await yahooFinance.quote(symbols);

        console.log('\n--- Quote Results ---');
        quotes.forEach(q => {
            console.log(`Symbol: ${q.symbol}`);
            console.log(`  Price: ${q.regularMarketPrice}`);
            console.log(`  Currency: ${q.currency}`);
            console.log(`  Name: ${q.shortName || q.longName}`);
            console.log('-------------------');
        });

        console.log(`\nFetched ${quotes.length} quotes for ${symbols.length} requested symbols.`);

    } catch (error) {
        console.error('Error fetching quotes:', error);
    }
})();
