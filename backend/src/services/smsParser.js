const { GoogleGenerativeAI } = require('@google/generative-ai');

class SmsParser {
  constructor() {
    this.genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    
    // Common bank and payment app identifiers
    this.bankSenders = [
      'SBIINB', 'HDFCBK', 'ICICIB', 'AXISBK', 'PNBSMS', 'KOTAKBK',
      'PAYTM', 'GPAY', 'PHONEPE', 'AMAZPAY', 'BHARPE', 'SBIPAY',
      'YESBNK', 'CITIBK', 'SCBANK', 'HSBC', 'IDBIBNK'
    ];
    
    // Regex patterns for different SMS formats
    this.patterns = {
      amount: /(?:Rs\.?|INR|₹)\s*([0-9,]+\.?\d*)/i,
      debit: /(?:debited|spent|paid|withdrawn|deducted|purchase|transaction|sent)/i,
      credit: /(?:credited|received|deposited|refund|cashback)/i,
      merchant: /(?:at|to|from|merchant)\s+([A-Za-z0-9\s&.-]+?)(?:\s+on|\s+dated|\s+for|\.|,|UPI)/i,
      upi: /(?:UPI|VPA|UPI ID):\s*([a-zA-Z0-9._-]+@[a-zA-Z]+)/i,
      account: /A\/c\s*(?:\*+)?(\d{4})/i,
      date: /(?:on|dated)\s+(\d{2}[-/]\d{2}[-/]\d{2,4})/i,
      time: /(?:at|@)\s+(\d{1,2}:\d{2}(?::\d{2})?(?:\s*[AP]M)?)/i,
      card: /(?:card|Card)\s*(?:ending\s*)?(?:\*+)?(\d{4})/i,
      refNo: /(?:Ref\.?|Reference|Txn)\s*(?:No\.?|ID|#)?\s*:?\s*([A-Z0-9]+)/i,
    };
  }

  /**
   * Check if SMS is from a bank/payment app
   */
  isPaymentSms(sender) {
    if (!sender) return false;
    const upperSender = sender.toUpperCase();
    return this.bankSenders.some(bank => upperSender.includes(bank));
  }

  /**
   * Parse SMS and extract transaction details
   */
  async parseSms(smsText, sender) {
    try {
      const transaction = {
        rawText: smsText,
        sender: sender,
        type: null,
        amount: null,
        merchant: null,
        description: null,
        category: null,
        categoryId: null,
        account: null,
        upiId: null,
        refNo: null,
        date: new Date(),
        confidence: 0,
        needsReview: false
      };

      // Extract amount
      const amountMatch = smsText.match(this.patterns.amount);
      if (amountMatch) {
        transaction.amount = parseFloat(amountMatch[1].replace(/,/g, ''));
      } else {
        // No amount found, can't process
        return null;
      }

      // Determine transaction type (debit/credit)
      if (this.patterns.debit.test(smsText)) {
        transaction.type = 'expense';
      } else if (this.patterns.credit.test(smsText)) {
        transaction.type = 'income';
      } else {
        // Can't determine type
        return null;
      }

      // Extract merchant name
      const merchantMatch = smsText.match(this.patterns.merchant);
      if (merchantMatch) {
        transaction.merchant = merchantMatch[1].trim();
        transaction.description = `Payment to ${transaction.merchant}`;
      }

      // Extract UPI ID
      const upiMatch = smsText.match(this.patterns.upi);
      if (upiMatch) {
        transaction.upiId = upiMatch[1];
        if (!transaction.merchant) {
          transaction.merchant = upiMatch[1].split('@')[0];
        }
      }

      // Extract account number
      const accountMatch = smsText.match(this.patterns.account) || 
                          smsText.match(this.patterns.card);
      if (accountMatch) {
        transaction.account = accountMatch[1];
      }

      // Extract reference number
      const refMatch = smsText.match(this.patterns.refNo);
      if (refMatch) {
        transaction.refNo = refMatch[1];
      }

      // Extract date if present
      const dateMatch = smsText.match(this.patterns.date);
      if (dateMatch) {
        try {
          transaction.date = this.parseDate(dateMatch[1]);
        } catch (e) {
          transaction.date = new Date();
        }
      }

      // AI-powered categorization for expenses
      if (transaction.type === 'expense' && transaction.merchant) {
        const category = await this.categorizeWithAI(
          transaction.merchant,
          smsText
        );
        transaction.category = category.name;
        transaction.categoryId = category.id;
        transaction.confidence = category.confidence;
        transaction.needsReview = category.confidence < 0.8;
      } else if (transaction.type === 'income') {
        transaction.category = 'Other Income';
        transaction.confidence = 0.7;
        transaction.needsReview = true;
      }

      return transaction;
    } catch (error) {
      console.error('Error parsing SMS:', error);
      return null;
    }
  }

  /**
   * Use Gemini AI to categorize transaction
   */
  async categorizeWithAI(merchant, fullText) {
    try {
      const model = this.genAI.getGenerativeModel({ 
        model: 'gemini-1.5-flash' 
      });

      const prompt = `
You are a financial transaction categorizer. Analyze this transaction and categorize it accurately.

Merchant/Description: ${merchant}
Full SMS Text: ${fullText}

Available Categories (return the exact category name and corresponding ID):
1. Food & Dining (id: "food_dining")
2. Transportation (id: "transportation")
3. Shopping (id: "shopping")
4. Bills & Utilities (id: "bills_utilities")
5. Entertainment (id: "entertainment")
6. Healthcare (id: "healthcare")
7. Education (id: "education")
8. Groceries (id: "groceries")
9. Travel (id: "travel")
10. Personal Care (id: "personal_care")
11. Fuel (id: "fuel")
12. Rent (id: "rent")
13. EMI/Loan (id: "emi_loan")
14. Insurance (id: "insurance")
15. Investment (id: "investment")
16. Other (id: "other")

Respond ONLY with valid JSON in this exact format (no markdown, no extra text):
{
  "name": "category_name",
  "id": "category_id",
  "confidence": 0.95,
  "reasoning": "brief explanation"
}`;

      const result = await model.generateContent(prompt);
      const response = await result.response.text();
      
      // Clean the response (remove markdown if present)
      const cleanResponse = response
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      
      const parsed = JSON.parse(cleanResponse);
      
      return {
        name: parsed.name || 'Other',
        id: parsed.id || 'other',
        confidence: parsed.confidence || 0.5,
        reasoning: parsed.reasoning || ''
      };
    } catch (error) {
      console.error('AI categorization error:', error);
      // Fallback to basic categorization
      return this.fallbackCategorize(merchant);
    }
  }

  /**
   * Fallback categorization using keyword matching
   */
  fallbackCategorize(merchant) {
    const merchantLower = merchant.toLowerCase();
    
    const categoryMap = {
      'food_dining': ['restaurant', 'cafe', 'food', 'pizza', 'burger', 'zomato', 'swiggy', 'dominos', 'mcdonald', 'kfc', 'starbucks'],
      'groceries': ['grocery', 'supermarket', 'market', 'store', 'dmart', 'reliance', 'bigbasket', 'grofers'],
      'transportation': ['uber', 'ola', 'rapido', 'metro', 'transport', 'taxi', 'auto', 'bus', 'railway'],
      'fuel': ['petrol', 'diesel', 'fuel', 'hp', 'bharat', 'iocl', 'shell'],
      'bills_utilities': ['electricity', 'water', 'gas', 'bill', 'utility', 'recharge', 'broadband'],
      'entertainment': ['movie', 'cinema', 'netflix', 'prime', 'spotify', 'hotstar', 'bookmyshow'],
      'shopping': ['amazon', 'flipkart', 'myntra', 'ajio', 'shop', 'mall', 'store'],
      'healthcare': ['hospital', 'clinic', 'pharmacy', 'medical', 'doctor', 'apollo', 'fortis'],
    };

    for (const [categoryId, keywords] of Object.entries(categoryMap)) {
      if (keywords.some(keyword => merchantLower.includes(keyword))) {
        return {
          name: this.getCategoryName(categoryId),
          id: categoryId,
          confidence: 0.75,
          reasoning: 'Keyword match'
        };
      }
    }

    return {
      name: 'Other',
      id: 'other',
      confidence: 0.5,
      reasoning: 'No match found'
    };
  }

  /**
   * Get category display name from ID
   */
  getCategoryName(categoryId) {
    const nameMap = {
      'food_dining': 'Food & Dining',
      'groceries': 'Groceries',
      'transportation': 'Transportation',
      'fuel': 'Fuel',
      'bills_utilities': 'Bills & Utilities',
      'entertainment': 'Entertainment',
      'shopping': 'Shopping',
      'healthcare': 'Healthcare',
      'education': 'Education',
      'travel': 'Travel',
      'personal_care': 'Personal Care',
      'rent': 'Rent',
      'emi_loan': 'EMI/Loan',
      'insurance': 'Insurance',
      'investment': 'Investment',
      'other': 'Other'
    };
    return nameMap[categoryId] || 'Other';
  }

  /**
   * Parse date from SMS format
   */
  parseDate(dateString) {
    const parts = dateString.split(/[-/]/);
    if (parts.length === 3) {
      // Handle DD-MM-YY or DD-MM-YYYY
      let [day, month, year] = parts;
      if (year.length === 2) {
        year = '20' + year;
      }
      return new Date(year, month - 1, day);
    }
    return new Date();
  }

  /**
   * Extract multiple transactions from bulk SMS
   */
  async parseBulkSms(smsArray) {
    const transactions = [];
    for (const sms of smsArray) {
      const transaction = await this.parseSms(sms.text, sms.sender);
      if (transaction) {
        transactions.push({
          ...transaction,
          smsId: sms.id,
          timestamp: sms.timestamp
        });
      }
    }
    return transactions;
  }
}

module.exports = new SmsParser();
