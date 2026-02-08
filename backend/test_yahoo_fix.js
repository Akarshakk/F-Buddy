const YahooFinance = require('yahoo-finance2').default;
const yahooFinance = new YahooFinance();

(async () => {
    try {
        console.log("Starting fix test...");
        const result = await yahooFinance.quote('AAPL');
        console.log("Result:", result.symbol, result.regularMarketPrice);
    } catch (e) {
        console.log("Caught Error:");
        console.log(e);
    }
})();
