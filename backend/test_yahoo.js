const yahooFinancePkg = require('yahoo-finance2');
const yahooFinance = yahooFinancePkg.default;

console.log('Is yahooFinance defined?', !!yahooFinance);
console.log('Is yahooFinance.quote a function?', typeof yahooFinance.quote);

const POPULAR_IND_STOCKS = ['RELIANCE.NS'];

async function test() {
    try {
        if (typeof yahooFinance.quote !== 'function') {
            console.log('Attempting to instantiate...');
            try {
                const yfInstance = new yahooFinance();
                console.log('Instance quote type:', typeof yfInstance.quote);
            } catch (e) {
                console.log('Instantiation failed:', e.message);
            }
        } else {
            console.log('Calling quote()...');
            // suppress warnings
            yahooFinance.setGlobalConfig({ validation: { logErrors: false } });
            const result = await yahooFinance.quote(POPULAR_IND_STOCKS[0]);
            console.log('Success single:', result.symbol);

            const results = await yahooFinance.quote(POPULAR_IND_STOCKS);
            console.log('Success array:', results.length);
        }
    } catch (e) {
        console.error('Test Error:', e);
    }
}

test();
