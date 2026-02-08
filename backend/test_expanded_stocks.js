const yahooFinance = require('./src/config/yahooFinance');

const POPULAR_IND_STOCKS = [
    // Nifty 50
    'RELIANCE.NS', 'TCS.NS', 'HDFCBANK.NS', 'ICICIBANK.NS', 'INFY.NS', 'SBIN.NS', 'BHARTIARTL.NS', 'ITC.NS', 'KOTAKBANK.NS', 'LICI.NS',
    'HINDUNILVR.NS', 'LT.NS', 'BAJFINANCE.NS', 'HCLTECH.NS', 'MARUTI.NS', 'SUNPHARMA.NS', 'ASIANPAINT.NS', 'TITAN.NS', 'AXISBANK.NS', 'ULTRACEMCO.NS',
    'TATASTEEL.NS', 'NTPC.NS', 'M&M.NS', 'POWERGRID.NS', 'TATAMOTORS.NS', 'ADANIENT.NS', 'BAJAJFINSV.NS', 'WIPRO.NS', 'COALINDIA.NS', 'ONGC.NS',
    'NESTLEIND.NS', 'JSWSTEEL.NS', 'TATACONSUM.NS', 'GRASIM.NS', 'ADANIPORTS.NS', 'EICHERMOT.NS', 'BPCL.NS', 'HINDALCO.NS', 'DRREDDY.NS', 'CIPLA.NS',
    'DIVISLAB.NS', 'SBILIFE.NS', 'BRITANNIA.NS', 'APOLLOHOSP.NS', 'TECHM.NS', 'HEROMOTOCO.NS', 'UPL.NS',

    // Nifty Next 50 & Others
    'ZOMATO.NS', 'PAYTM.NS', 'HAL.NS', 'BEL.NS', 'TRENT.NS', 'JIOFIN.NS', 'VBL.NS', 'CHOLAFIN.NS', 'SIEMENS.NS', 'DLF.NS',
    'PIDILITIND.NS', 'IOC.NS', 'BANKBARODA.NS', 'GAIL.NS', 'RECLTD.NS', 'SHRIRAMFIN.NS', 'ADANIPOWER.NS', 'ADANIGREEN.NS', 'AMBUJACEM.NS', 'TVSMOTOR.NS',
    'HAVELLS.NS', 'DABUR.NS', 'ABB.NS', 'VEDL.NS', 'GODREJCP.NS', 'INDUSINDBK.NS', 'NAUKRI.NS', 'ICICIGI.NS', 'SBICARD.NS', 'TATAPOWER.NS',
    'IRCTC.NS', 'BOSCHLTD.NS', 'BERGEPAINT.NS', 'MUTHOOTFIN.NS', 'PIIND.NS', 'MOTHERSON.NS', 'LTIM.NS', 'ICICIPRULI.NS', 'MARICO.NS', 'CANBK.NS',
    'POLYCAB.NS', 'SRF.NS', 'TORNTPHARM.NS', 'INDIGO.NS', 'PNB.NS', 'JINDALSTEL.NS', 'LUPIN.NS', 'AUROPHARMA.NS', 'TIINDIA.NS', 'ALKEM.NS',

    // US Tech
    'AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'NVDA', 'META', 'NFLX', 'AMD', 'INTC'
];

async function runBenchmark() {
    console.log(`Starting benchmark for ${POPULAR_IND_STOCKS.length} stocks...`);
    const start = Date.now();

    try {
        const quotes = await yahooFinance.quote(POPULAR_IND_STOCKS);
        const duration = (Date.now() - start) / 1000;

        console.log(`✅ Successfully fetched ${quotes.length} quotes in ${duration.toFixed(2)}s`);

        // Validation
        const missing = POPULAR_IND_STOCKS.length - quotes.length;
        if (missing > 0) {
            console.warn(`⚠️ Warning: ${missing} stocks returned no data.`);
        }

        // Sample check
        const reliance = quotes.find(q => q.symbol === 'RELIANCE.NS');
        if (reliance) {
            console.log(`Sample: ${reliance.symbol} - ₹${reliance.regularMarketPrice}`);
        } else {
            console.log('Sample RELIANCE.NS not found');
        }

        const aapl = quotes.find(q => q.symbol === 'AAPL');
        if (aapl) {
            console.log(`Sample: ${aapl.symbol} - $${aapl.regularMarketPrice}`);
        }

    } catch (e) {
        console.error('❌ Fetch failed:', e.message);
    }
}

runBenchmark();
