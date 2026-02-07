const YahooFinance = require('yahoo-finance2').default;

// Create a single shared instance
const yahooFinance = new YahooFinance();

// Optional: Configure validation or logging here if needed
// yahooFinance.setGlobalConfig({ ... });

module.exports = yahooFinance;
