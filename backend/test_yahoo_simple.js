const yahooFinance = require('yahoo-finance2').default;

(async () => {
    try {
        console.log("Starting...");
        const result = await yahooFinance.quote('AAPL');
        console.log("Result:", result.symbol);
    } catch (e) {
        console.log("Caught Error:");
        console.log(e.message);
        console.log(JSON.stringify(e));
    }
})();
