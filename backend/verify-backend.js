/**
 * Quick Backend Verification Script
 * Tests if the backend is running and responding correctly
 */

const http = require('http');

const BASE_URL = 'http://localhost:5001';

console.log('🔍 Verifying Backend...\n');

function makeRequest(path) {
    return new Promise((resolve, reject) => {
        http.get(`${BASE_URL}${path}`, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, data: JSON.parse(data) });
                } catch (e) {
                    resolve({ status: res.statusCode, data: data });
                }
            });
        }).on('error', reject);
    });
}

async function verify() {
    try {
        // Test 1: Health Check
        console.log('1️⃣ Testing health endpoint...');
        const health = await makeRequest('/api/health');
        if (health.status === 200) {
            console.log('   ✅ Backend is running');
            console.log(`   Message: ${health.data.message}`);
        } else {
            console.log('   ❌ Health check failed');
            return false;
        }

        // Test 2: Auth Test Endpoint
        console.log('\n2️⃣ Testing auth endpoint...');
        const authTest = await makeRequest('/api/test-auth');
        if (authTest.status === 200) {
            console.log('   ✅ Auth endpoint responding');
        } else {
            console.log('   ⚠️  Auth test endpoint not found (non-critical)');
        }

        console.log('\n' + '='.repeat(50));
        console.log('✅ Backend is running correctly!');
        console.log('='.repeat(50));
        console.log('\n💡 Next steps:');
        console.log('   1. Test KYC flow: npm run test-kyc');
        console.log('   2. Open FRONTEND_EXAMPLE.html in browser');
        console.log('   3. Update your frontend to include Authorization header');
        console.log('\n📚 Documentation:');


        return true;

    } catch (error) {
        console.log('\n' + '='.repeat(50));
        console.log('❌ Backend is not running!');
        console.log('='.repeat(50));
        console.log('\nError:', error.message);
        console.log('\n💡 To start the backend:');
        console.log('   cd backend');
        console.log('   npm run dev');
        return false;
    }
}

verify().then(success => {
    process.exit(success ? 0 : 1);
});
