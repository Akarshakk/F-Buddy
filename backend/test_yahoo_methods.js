const YahooFinance = require('yahoo-finance2').default;
const yahooFinance = new YahooFinance({ validation: { logErrors: false } });

console.log('Instance methods:');
console.log(Object.getOwnPropertyNames(Object.getPrototypeOf(yahooFinance)));

// Try to find historical or chart
try {
    if (yahooFinance.history) console.log('Found history()');
    if (yahooFinance.historical) console.log('Found historical()');
    if (yahooFinance.chart) console.log('Found chart()');
} catch (e) { }

(async () => {
    try {
        // Try chart as fallback
        console.log('Testing chart()...');
        const result = await yahooFinance.chart('AAPL', { period1: '2023-01-01', interval: '1d' });
        console.log('Chart success:', result.meta.symbol, result.quotes.length);
    } catch (e) {
        console.log('Chart failed:', e.message);
    }
})();
