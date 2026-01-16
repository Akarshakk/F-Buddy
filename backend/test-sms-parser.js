/**
 * SMS Parser Test Script
 * Test the SMS parsing functionality with sample messages
 */

require('dotenv').config();
const smsParser = require('./src/services/smsParser');

// Sample SMS messages from different banks and payment apps
const testMessages = [
  // SBI Debit
  {
    sender: 'SBIINB',
    text: 'Rs.500.00 debited from A/c *1234 on 15-01-26 to Swiggy via UPI. Ref No: 401234567890. Available Bal: Rs.10000.00'
  },
  
  // HDFC Credit
  {
    sender: 'HDFCBK',
    text: 'INR 1000.00 credited to A/c *5678 on 15-01-26 from Salary Transfer. Ref: HDC123456789'
  },
  
  // PhonePe Payment
  {
    sender: 'PHONEPE',
    text: 'You paid Rs.299 to Netflix via PhonePe. UPI ID: netflix@icici. Txn ID: T2026011512345'
  },
  
  // Google Pay
  {
    sender: 'GPAY',
    text: 'Rs.750 sent to Amazon on 15-01-26 using Google Pay. UPI: amazon@axis. Balance: Rs.5000'
  },
  
  // Paytm
  {
    sender: 'PAYTM',
    text: 'Rs.1500 debited from Paytm Wallet for payment to Zomato. Order ID: 123456789'
  },
  
  // ICICI Fuel
  {
    sender: 'ICICIB',
    text: 'Rs.2000.00 spent at HP PETROL PUMP on Card *4567 on 15-01-26. Ref: IC789012345'
  },
  
  // Axis Grocery
  {
    sender: 'AXISBK',
    text: 'INR 850.50 debited from A/c *8901 at DMART on 15-01-26. Available Balance: Rs.25000'
  },
  
  // UPI Transfer
  {
    sender: 'SBIINB',
    text: 'Rs.5000 transferred to John Doe via UPI. VPA: john@okaxis. UTR: 402612345678'
  },
  
  // Bill Payment
  {
    sender: 'HDFCBK',
    text: 'Rs.1200 debited for Electricity Bill Payment on 15-01-26. Biller: MSEB. Ref: BILL123456'
  },
  
  // Movie Ticket
  {
    sender: 'ICICIB',
    text: 'Rs.600 spent at BOOKMYSHOW on Card *1234. Show: Avengers. Booking ID: BMS123456'
  },
  
  // Uber Ride
  {
    sender: 'AXISBK',
    text: 'Rs.250 debited for payment to UBER INDIA on 15-01-26. Trip ID: UBER123'
  },
  
  // Medicine Purchase
  {
    sender: 'GPAY',
    text: 'Paid Rs.450 to Apollo Pharmacy using Google Pay. UPI: apollo@icici'
  },
  
  // Refund/Credit
  {
    sender: 'PHONEPE',
    text: 'Rs.199 refund credited for cancelled order from Flipkart. Order ID: FLP123456789'
  },
  
  // Invalid/Non-payment SMS
  {
    sender: 'SBIINB',
    text: 'Your SBI account statement for Jan 2026 is ready. Login to view.'
  },
  
  // Ambiguous merchant
  {
    sender: 'HDFCBK',
    text: 'Rs.350 debited from A/c *2345 on 15-01-26. Ref: XYZ123'
  }
];

// Color codes for console output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m'
};

async function runTests() {
  console.log('\n' + '='.repeat(80));
  console.log('🧪 SMS PARSER TEST SUITE');
  console.log('='.repeat(80) + '\n');

  let totalTests = 0;
  let successfulParses = 0;
  let failedParses = 0;
  let highConfidence = 0;
  let needsReview = 0;

  for (let i = 0; i < testMessages.length; i++) {
    const { sender, text } = testMessages[i];
    totalTests++;

    console.log(`${colors.cyan}Test ${i + 1}/${testMessages.length}${colors.reset}`);
    console.log(`${colors.blue}Sender:${colors.reset} ${sender}`);
    console.log(`${colors.blue}SMS:${colors.reset} ${text}`);
    console.log('─'.repeat(80));

    try {
      const result = await smsParser.parseSms(text, sender);

      if (result) {
        successfulParses++;
        
        // Display parsed result
        console.log(`${colors.green}✓ Successfully Parsed${colors.reset}`);
        console.log(`  Type:        ${result.type === 'expense' ? '🔴 Expense' : '🟢 Income'}`);
        console.log(`  Amount:      ₹${result.amount}`);
        console.log(`  Merchant:    ${result.merchant || 'N/A'}`);
        console.log(`  Category:    ${result.category || 'N/A'}`);
        console.log(`  Confidence:  ${(result.confidence * 100).toFixed(1)}%`);
        console.log(`  Needs Review: ${result.needsReview ? colors.yellow + 'Yes' + colors.reset : colors.green + 'No' + colors.reset}`);
        
        if (result.upiId) {
          console.log(`  UPI ID:      ${result.upiId}`);
        }
        if (result.refNo) {
          console.log(`  Ref No:      ${result.refNo}`);
        }

        if (result.confidence >= 0.8) {
          highConfidence++;
        } else {
          needsReview++;
        }
      } else {
        failedParses++;
        console.log(`${colors.red}✗ Failed to Parse${colors.reset}`);
        console.log(`  Reason: Could not extract transaction details`);
      }
    } catch (error) {
      failedParses++;
      console.log(`${colors.red}✗ Error${colors.reset}`);
      console.log(`  Error: ${error.message}`);
    }

    console.log('\n');
  }

  // Summary
  console.log('='.repeat(80));
  console.log('📊 TEST SUMMARY');
  console.log('='.repeat(80));
  console.log(`Total Tests:           ${totalTests}`);
  console.log(`${colors.green}Successful Parses:     ${successfulParses}${colors.reset}`);
  console.log(`${colors.red}Failed Parses:         ${failedParses}${colors.reset}`);
  console.log(`${colors.green}High Confidence:       ${highConfidence} (≥80%)${colors.reset}`);
  console.log(`${colors.yellow}Needs Review:          ${needsReview} (<80%)${colors.reset}`);
  console.log(`Success Rate:          ${((successfulParses / totalTests) * 100).toFixed(1)}%`);
  console.log(`Auto-save Rate:        ${((highConfidence / totalTests) * 100).toFixed(1)}%`);
  console.log('='.repeat(80) + '\n');
}

// Run tests
console.log('\n🚀 Starting SMS Parser Tests...\n');
runTests().then(() => {
  console.log('✅ All tests completed!\n');
  process.exit(0);
}).catch(error => {
  console.error('❌ Test suite failed:', error);
  process.exit(1);
});
