const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { protect } = require('../middleware/auth');

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

// Ensure upload directory exists
const uploadDir = path.join(__dirname, '../../uploads/statements');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Multer Config
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const userId = req.user ? req.user.id : 'anonymous';
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    cb(null, `${userId}-${Date.now()}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 15 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    console.log('[Statement] File:', file.originalname);
    cb(null, true);
  }
});

// Convert file to Gemini format
function fileToGenerativePart(filePath, mimeType) {
  return {
    inlineData: {
      data: Buffer.from(fs.readFileSync(filePath)).toString('base64'),
      mimeType
    },
  };
}

// Get MIME type from file
function getMimeType(filename) {
  const ext = path.extname(filename).toLowerCase();
  const mimeTypes = {
    '.pdf': 'application/pdf',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.gif': 'image/gif',
  };
  return mimeTypes[ext] || 'application/octet-stream';
}

// Parse bank statement using Gemini AI
async function parseStatementWithGemini(filePath, mimeType) {
  try {
    console.log('[Gemini] Processing file with AI...');
    
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
    
    const prompt = `You are an expert bank statement analyzer. Extract ALL transactions from this bank statement with 100% accuracy.

CRITICAL INSTRUCTIONS:
1. Extract EVERY SINGLE transaction - do not skip any row
2. Look for table format with columns like: Date | Description/Particulars | Withdrawal/Debit | Deposit/Credit | Balance
3. COLUMN-BASED CLASSIFICATION (HIGHEST PRIORITY):
   - If amount is in "Withdrawal" column → type: "debit"
   - If amount is in "Deposits" column → type: "credit"
   - If amount is in "Debit" or "Dr" column → type: "debit"
   - If amount is in "Credit" or "Cr" column → type: "credit"
4. Process the ENTIRE document, all pages

TRANSACTION TYPE CLASSIFICATION:
RULE 1 (MOST IMPORTANT): Check which column the amount appears in:
- Withdrawal column = DEBIT
- Deposits column = CREDIT
- Debit/Dr column = DEBIT
- Credit/Cr column = CREDIT

RULE 2 (If no clear columns): Use keywords:
- Keywords for DEBIT: Dr, DR, Debit, Debited, Withdrawal, Paid, Purchase, Payment, Sent, Transferred, ATM, POS, EMI, Bill Payment, Spent
- Keywords for CREDIT: Cr, CR, Credit, Credited, Deposit, Received, Refund, Cashback, Salary, Interest, Dividend, By Transfer

PAYMENT MODE DETECTION:
- UPI: Look for "UPI", "IMPS", or app names
  - "GPay" or "Google Pay" → "Google Pay (UPI)"
  - "PhonePe" → "PhonePe (UPI)"
  - "Paytm" → "Paytm (UPI)"
  - "BHIM" → "BHIM (UPI)"
  - "Amazon Pay" → "Amazon Pay (UPI)"
  - "WhatsApp" → "WhatsApp (UPI)"
  - Generic UPI → "UPI"
- Cards:
  - "ATM", "POS", "Debit Card" → "Debit Card"
  - "Credit Card", "CC" → "Credit Card"
- Bank Transfer:
  - "NEFT" → "NEFT"
  - "RTGS" → "RTGS"
  - "IMPS" → "IMPS"
  - "Net Banking", "Online Transfer" → "Net Banking"
- Default → "Bank Transfer"

EXTRACTION RULES:
- date: Extract in DD/MM/YYYY or DD-MM-YYYY format
- amount: Extract the numeric value only (no currency symbols)
- merchant: Extract from description/particulars (company/person name)
- description: Full transaction description text
- upiId: Extract if format is xxx@xxx
- refNumber: Extract reference/UTR/transaction number
- cardLast4: Extract last 4 digits if card transaction
- balance: Extract closing balance if shown

OUTPUT FORMAT (JSON only, no markdown):
{
  "transactions": [
    {
      "date": "17/01/2026",
      "amount": 1234.56,
      "type": "debit",
      "paymentMode": "Google Pay (UPI)",
      "merchant": "Swiggy",
      "description": "UPI-SWIGGY-GOOGLE PAY",
      "upiId": "swiggy@paytm",
      "refNumber": "402312345678",
      "cardLast4": null,
      "balance": 45678.90
    }
  ]
}

IMPORTANT: Return ONLY the JSON object, no explanations or markdown formatting.`;

    const imagePart = fileToGenerativePart(filePath, mimeType);
    const result = await model.generateContent([prompt, imagePart]);
    const response = await result.response;
    const text = response.text();
    
    console.log('[Gemini] Response received, length:', text.length);
    
    // Extract JSON from response (remove markdown if present)
    let jsonText = text.trim();
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```\n?/g, '');
    }
    
    const parsed = JSON.parse(jsonText);
    return parsed.transactions || [];
    
  } catch (error) {
    console.error('[Gemini] Error:', error.message);
    throw new Error('Failed to parse statement with AI: ' + error.message);
  }
}

// POST /api/statement/upload
router.post('/upload', protect, (req, res, next) => {
  upload.single('statement')(req, res, (err) => {
    if (err) {
      return res.status(400).json({ success: false, message: err.message });
    }
    next();
  });
}, async (req, res) => {
  let filePath = null;
  
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }
    
    // Check if Gemini API key is configured
    if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY === 'your_gemini_api_key_here') {
      fs.unlink(req.file.path, () => {});
      return res.status(500).json({ 
        success: false, 
        message: 'Gemini API key not configured. Please add GEMINI_API_KEY to .env file.' 
      });
    }
    
    filePath = req.file.path;
    const originalName = req.file.originalname || '';
    const mimeType = getMimeType(originalName);
    
    console.log('[Statement] Processing:', originalName, 'Type:', mimeType);
    
    // Parse with Gemini AI
    const transactions = await parseStatementWithGemini(filePath, mimeType);
    
    console.log('[Statement] Found', transactions.length, 'transactions');
    
    // Calculate summary
    const debitTxns = transactions.filter(t => t.type === 'debit');
    const creditTxns = transactions.filter(t => t.type === 'credit');
    
    // Group by payment mode
    const byPaymentMode = {};
    transactions.forEach(t => {
      const mode = t.paymentMode || 'Unknown';
      byPaymentMode[mode] = (byPaymentMode[mode] || 0) + 1;
    });
    
    const summary = {
      totalTransactions: transactions.length,
      totalDebit: Math.round(debitTxns.reduce((sum, t) => sum + (t.amount || 0), 0) * 100) / 100,
      totalCredit: Math.round(creditTxns.reduce((sum, t) => sum + (t.amount || 0), 0) * 100) / 100,
      debitCount: debitTxns.length,
      creditCount: creditTxns.length,
      unknownCount: transactions.filter(t => t.type !== 'debit' && t.type !== 'credit').length,
      byPaymentMode,
    };
    
    // Clean up file
    fs.unlink(filePath, () => {});
    
    res.json({
      success: true,
      message: transactions.length > 0 
        ? `Found ${transactions.length} transactions (${debitTxns.length} debits, ${creditTxns.length} credits)` 
        : 'No transactions found in the statement.',
      transactions,
      summary,
      parsedBy: 'Gemini AI',
    });
    
  } catch (error) {
    console.error('[Statement] Error:', error.message);
    if (filePath) fs.unlink(filePath, () => {});
    res.status(500).json({ 
      success: false, 
      message: 'Failed to process statement: ' + error.message 
    });
  }
});

module.exports = router;
