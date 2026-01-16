/**
 * SMS API Endpoint Test Script
 * Test the SMS API endpoints with sample data
 */

require('dotenv').config();
const axios = require('axios');

const BASE_URL = 'http://localhost:5001/api';

// Sample test data
const testSMS = {
  sender: 'SBIINB',
  text: 'Rs.500.00 debited from A/c *1234 on 15-01-26 to Swiggy via UPI. Ref No: 401234567890',
  smsId: 'TEST_' + Date.now()
};

const testBulkSMS = [
  {
    sender: 'HDFCBK',
    text: 'Rs.750 debited from A/c *5678 at Amazon on 15-01-26',
    id: 'BULK_1',
    timestamp: new Date().toISOString()
  },
  {
    sender: 'GPAY',
    text: 'Rs.299 paid to Netflix using Google Pay',
    id: 'BULK_2',
    timestamp: new Date().toISOString()
  },
  {
    sender: 'PHONEPE',
    text: 'Rs.1500 sent to Zomato via PhonePe',
    id: 'BULK_3',
    timestamp: new Date().toISOString()
  }
];

// You need to get a valid JWT token first by logging in
// Replace this with your actual token
let authToken = '';

// Helper function to make authenticated requests
async function request(method, endpoint, data = null) {
  const config = {
    method,
    url: `${BASE_URL}${endpoint}`,
    headers: authToken ? { Authorization: `Bearer ${authToken}` } : {},
    data
  };

  try {
    const response = await axios(config);
    return { success: true, data: response.data };
  } catch (error) {
    return {
      success: false,
      error: error.response?.data || error.message
    };
  }
}

async function testLogin() {
  console.log('\n🔐 Testing Login...');
  console.log('─'.repeat(80));

  const response = await request('POST', '/auth/login', {
    email: 'test@example.com',
    password: 'password123'
  });

  if (response.success && response.data.token) {
    authToken = response.data.token;
    console.log('✅ Login successful!');
    console.log(`   Token: ${authToken.substring(0, 20)}...`);
    return true;
  } else {
    console.log('❌ Login failed. Please register first or update credentials.');
    console.log('   Creating test account...');
    
    // Try to register
    const registerResponse = await request('POST', '/auth/register', {
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    });

    if (registerResponse.success && registerResponse.data.token) {
      authToken = registerResponse.data.token;
      console.log('✅ Registration successful!');
      return true;
    }
    
    console.log('❌ Could not authenticate. Please login manually first.');
    return false;
  }
}

async function testParseSMS() {
  console.log('\n📱 Testing SMS Parse Endpoint...');
  console.log('─'.repeat(80));

  const response = await request('POST', '/sms/parse', {
    smsText: testSMS.text,
    sender: testSMS.sender,
    smsId: testSMS.smsId
  });

  if (response.success) {
    console.log('✅ SMS parsed successfully!');
    console.log(JSON.stringify(response.data, null, 2));
    return response.data.transaction;
  } else {
    console.log('❌ Parse failed:', response.error);
    return null;
  }
}

async function testSaveSMS(transaction) {
  console.log('\n💾 Testing SMS Save Endpoint...');
  console.log('─'.repeat(80));

  if (!transaction) {
    console.log('⚠️  No transaction to save (parse failed)');
    return null;
  }

  const response = await request('POST', '/sms/save', {
    transaction,
    smsId: testSMS.smsId
  });

  if (response.success) {
    console.log('✅ Transaction saved successfully!');
    console.log(JSON.stringify(response.data, null, 2));
    return response.data.transaction;
  } else {
    console.log('❌ Save failed:', response.error);
    return null;
  }
}

async function testBulkParse() {
  console.log('\n📚 Testing Bulk SMS Parse...');
  console.log('─'.repeat(80));

  const response = await request('POST', '/sms/parse-bulk', {
    smsArray: testBulkSMS
  });

  if (response.success) {
    console.log('✅ Bulk parse successful!');
    console.log(`   Total: ${response.data.total}`);
    console.log(`   Unique: ${response.data.unique}`);
    console.log(`   Duplicates: ${response.data.duplicates}`);
    console.log(JSON.stringify(response.data.transactions, null, 2));
    return response.data.transactions;
  } else {
    console.log('❌ Bulk parse failed:', response.error);
    return null;
  }
}

async function testGetSMSTransactions() {
  console.log('\n📊 Testing Get SMS Transactions...');
  console.log('─'.repeat(80));

  const response = await request('GET', '/sms/transactions');

  if (response.success) {
    console.log('✅ Retrieved SMS transactions!');
    console.log(`   Total: ${response.data.total}`);
    console.log(`   Expenses: ${response.data.expenses?.length || 0}`);
    console.log(`   Incomes: ${response.data.incomes?.length || 0}`);
    return response.data;
  } else {
    console.log('❌ Get transactions failed:', response.error);
    return null;
  }
}

async function runAPITests() {
  console.log('\n' + '='.repeat(80));
  console.log('🧪 SMS API ENDPOINT TESTS');
  console.log('='.repeat(80));

  // Step 1: Login
  const loginSuccess = await testLogin();
  if (!loginSuccess) {
    console.log('\n❌ Cannot proceed without authentication');
    return;
  }

  // Step 2: Parse SMS
  const transaction = await testParseSMS();

  // Step 3: Save SMS Transaction
  await testSaveSMS(transaction);

  // Step 4: Bulk Parse
  await testBulkParse();

  // Step 5: Get SMS Transactions
  await testGetSMSTransactions();

  console.log('\n' + '='.repeat(80));
  console.log('✅ All API tests completed!');
  console.log('='.repeat(80) + '\n');
}

// Run tests
console.log('\n🚀 Starting SMS API Tests...\n');
console.log('⚠️  Make sure the backend server is running on http://localhost:5001\n');

runAPITests().then(() => {
  process.exit(0);
}).catch(error => {
  console.error('❌ Test suite failed:', error);
  process.exit(1);
});
