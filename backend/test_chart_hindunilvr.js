const yahooFinance = require('./src/config/yahooFinance');

(async () => {
    try {
        const symbol = 'HINDUNILVR.NS';
        console.log(`Fetching chart for ${symbol}...`);

        const end = new Date();
        let start = new Date();
        start.setMonth(start.getMonth() - 1); // 1 Month history

        const queryOptions = { period1: start, period2: end, interval: '1d' };
        console.log('Query Options:', queryOptions);

        const result = await yahooFinance.chart(symbol, queryOptions);

        if (result && result.quotes && result.quotes.length > 0) {
            console.log('Success!');
            console.log('Quotes count:', result.quotes.length);
            console.log('First quote:', result.quotes[0]);
        } else {
            console.log('Failed: No quotes returned.');
            console.log('Result:', JSON.stringify(result, null, 2));
        }

    } catch (error) {
        console.error('Error fetching chart:', error);
        if (error.errors) {
            console.error('Validation errors:', JSON.stringify(error.errors, null, 2));
        }
    }
})();
