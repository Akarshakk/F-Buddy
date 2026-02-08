const pkg = require('yahoo-finance2');

console.log('Package keys:', Object.keys(pkg));
console.log('Package.setGlobalConfig type:', typeof pkg.setGlobalConfig);

const YahooFinance = pkg.default;
try {
    console.log('Attempting constructor config...');
    const yf = new YahooFinance({
        validation: { logErrors: false }
    });
    console.log('Instance created successfully');
} catch (e) {
    console.error('Constructor config failed:', e.message);
}
