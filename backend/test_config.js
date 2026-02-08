const YahooFinance = require('yahoo-finance2').default;

try {
    console.log('Static setGlobalConfig?', typeof YahooFinance.setGlobalConfig);

    const yf = new YahooFinance();
    console.log('Instance setGlobalConfig?', typeof yf.setGlobalConfig);

    console.log('Attempting constructor config...');
    // Try passing config to constructor?
    // Inspect the instance to see if we can find config
} catch (e) {
    console.error(e);
}
