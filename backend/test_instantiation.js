try {
    const YahooFinance = require('yahoo-finance2').default;
    console.log('YahooFinance imported. Type:', typeof YahooFinance);
    const yahooFinance = new YahooFinance({ validation: { logErrors: false } });
    console.log('Instance created.');

    (async () => {
        try {
            console.log("Fetching quote for array...");
            const quotes = await yahooFinance.quote(['AAPL', 'MSFT']);
            console.log("Quotes count:", quotes.length);
            console.log("First quote:", quotes[0].symbol);
        } catch (e) {
            console.error("Quote Error:", e);
        }
    })();
} catch (error) {
    console.error("Instantiation Error:", error);
}
