const yahooFinance = require('./src/config/yahooFinance');

async function test() {
    try {
        const symbol = 'HINDUNILVR.NS';
        const quote = await yahooFinance.quote(symbol);
        const fs = require('fs');
        fs.writeFileSync('quote_result.json', JSON.stringify(quote, null, 2));
        console.log('Quote saved to quote_result.json');
    } catch (e) {
        console.error('Error:', e);
    }
}

test();
