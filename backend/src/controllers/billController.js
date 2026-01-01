const Tesseract = require('tesseract.js');

// Available categories in the app
const CATEGORIES = [
  'food', 'restaurants', 'drinks', 'transport', 'fuel', 'clothes',
  'education', 'health', 'hotel', 'fun', 'personal', 'pets', 'others'
];

// Pre-process OCR text for better extraction
const preprocessText = (text) => {
  return text
    .replace(/[|\\]/g, 'I')  // Common OCR mistake
    .replace(/[oO](?=\d)/g, '0')  // O before numbers is likely 0
    .replace(/(?<=\d)[oO]/g, '0')  // O after numbers is likely 0
    .replace(/[lI](?=\d{2,})/g, '1')  // l or I before numbers is likely 1
    .replace(/\s+/g, ' ')  // Normalize spaces
    .trim();
};

// LLM-based bill extraction using Gemini API (extracts all details)
const extractWithLLM = async (text) => {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    
    if (!apiKey) {
      console.log('No Gemini API key found, falling back to regex extraction');
      return null;
    }

    // Pre-process text for better LLM understanding
    const cleanText = preprocessText(text);

    const prompt = `Extract bill info. Return ONLY JSON, nothing else.

BILL TEXT:
${cleanText.substring(0, 1500)}

RULES:
- merchant: Store/restaurant name (MAX 25 chars, just the name, no address)
- amount: Final total (number only, after taxes, look for "Bill Total", "Grand Total", "Total Rs")
- category: One of: restaurants, food, drinks, transport, fuel, clothes, education, health, hotel, fun, personal, pets, others
- date: YYYY-MM-DD format or null

CATEGORY HINTS:
- restaurants: dine-in, menu items, FSSAI, Table No, kitchen, cafe, dhaba
- food: Zomato, Swiggy, grocery, supermarket

RESPOND WITH ONLY:
{"merchant":"Name","amount":123,"category":"restaurants","date":"2025-12-31"}`;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [{
            parts: [{ text: prompt }]
          }],
          generationConfig: {
            temperature: 0.05,  // Very low for consistent extraction
            maxOutputTokens: 150,
          }
        })
      }
    );

    if (!response.ok) {
      console.error('Gemini API error:', response.status);
      return null;
    }

    const data = await response.json();
    const responseText = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    
    if (!responseText) {
      return null;
    }
    
    // Parse JSON response
    try {
      // Remove any markdown code block markers if present
      let jsonStr = responseText
        .replace(/```json\n?|\n?```/g, '')
        .replace(/```\n?|\n?```/g, '')
        .trim();
      
      // Try to extract JSON if there's extra text
      const jsonMatch = jsonStr.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        jsonStr = jsonMatch[0];
      }
      
      const result = JSON.parse(jsonStr);
      
      // Validate and clean the response
      if (result.category && !CATEGORIES.includes(result.category.toLowerCase())) {
        result.category = 'others';
      } else if (result.category) {
        result.category = result.category.toLowerCase();
      }
      
      // Ensure amount is a number
      if (result.amount && typeof result.amount === 'string') {
        result.amount = parseFloat(result.amount.replace(/[^0-9.]/g, ''));
      }
      
      console.log('LLM extracted:', result);
      return result;
    } catch (parseError) {
      console.error('Failed to parse LLM response:', responseText);
      return null;
    }
  } catch (error) {
    console.error('LLM extraction error:', error.message);
    return null;
  }
};

// LLM-based categorization using Gemini API (free tier)
const categorizeWithLLM = async (text) => {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    
    if (!apiKey) {
      console.log('No Gemini API key found, falling back to keyword matching');
      return null;
    }

    const prompt = `You are a bill/receipt categorization expert. Analyze the following bill/receipt text and categorize it into EXACTLY ONE of these categories:
- food (groceries, food delivery like Zomato/Swiggy, fast food)
- restaurants (dine-in restaurants, cafes)
- drinks (bars, beverages, alcohol)
- transport (uber, ola, taxi, metro, flights, trains)
- fuel (petrol, diesel, gas stations)
- clothes (apparel, footwear, fashion)
- education (schools, courses, books, stationery)
- health (hospitals, medicines, pharmacy, gym)
- hotel (hotels, resorts, accommodation)
- fun (movies, entertainment, subscriptions, gaming)
- personal (salon, grooming, cosmetics)
- pets (pet food, vet, pet supplies)
- others (anything that doesn't fit above)

Bill/Receipt text:
"""
${text.substring(0, 1500)}
"""

Respond with ONLY the category name in lowercase, nothing else.`;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [{
            parts: [{ text: prompt }]
          }],
          generationConfig: {
            temperature: 0.1,
            maxOutputTokens: 20,
          }
        })
      }
    );

    if (!response.ok) {
      console.error('Gemini API error:', response.status);
      return null;
    }

    const data = await response.json();
    const category = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim().toLowerCase();
    
    // Validate the category is one of our allowed categories
    if (category && CATEGORIES.includes(category)) {
      console.log(`LLM categorized as: ${category}`);
      return category;
    }
    
    console.log(`LLM returned invalid category: ${category}`);
    return null;
  } catch (error) {
    console.error('LLM categorization error:', error.message);
    return null;
  }
};

// Category keywords mapping - fallback for when LLM is unavailable
const categoryKeywords = {
  food: [
    'zomato', 'swiggy', 'dominos', 'pizza', 'burger', 'mcdonald', 'kfc', 
    'subway', 'starbucks', 'bakery', 'snacks', 'ice cream',
    'food delivery', 'groceries', 'supermarket', 'bigbasket', 'blinkit',
    'zepto', 'instamart', 'dmart', 'more supermarket', 'reliance fresh'
  ],
  restaurants: [
    'restaurant', 'diner', 'bistro', 'eatery', 'dhaba', 'kitchen', 'grill',
    'buffet', 'bar & grill', 'fine dining', 'casual dining', 'table service',
    'veg treat', 'foodlink', 'food link', 'family restaurant', 'food plaza',
    'food court', 'cafe', 'coffee', 'tandoor', 'biryani', 'chinese', 'italian',
    'mexican', 'thai', 'indian', 'mughlai', 'punjabi', 'south indian',
    'north indian', 'continental', 'multi cuisine', 'pure veg', 'non veg',
    'canteen', 'mess', 'tiffin', 'lunch', 'dinner', 'breakfast', 'brunch',
    'starter', 'main course', 'dessert', 'appetizer', 'combo meal', 'thali',
    'paratha', 'dosa', 'idli', 'vada', 'sambar', 'chutney', 'naan', 'roti',
    'curry', 'gravy', 'rice', 'dal', 'paneer', 'chicken', 'mutton', 'fish',
    'prawns', 'kebab', 'tikka', 'manchurian', 'noodles', 'fried rice',
    'momos', 'chowmein', 'spring roll', 'soup', 'salad', 'raita'
  ],
  drinks: [
    'bar', 'pub', 'brewery', 'wine', 'beer', 'whiskey', 'vodka', 'rum',
    'cocktail', 'mocktail', 'juice', 'smoothie', 'shake', 'soda', 'cola',
    'pepsi', 'coca cola', 'sprite', 'fanta', 'thums up', 'limca'
  ],
  transport: [
    'uber', 'ola', 'rapido', 'lyft', 'taxi', 'cab', 'auto', 'rickshaw',
    'metro', 'railway', 'irctc', 'train', 'bus', 'redbus', 'abhibus',
    'airport', 'airlines', 'flight', 'indigo', 'spicejet', 'air india',
    'vistara', 'goair', 'parking', 'toll', 'fastag'
  ],
  fuel: [
    'petrol', 'diesel', 'cng', 'lpg', 'gas station', 'fuel', 'petroleum',
    'indian oil', 'bharat petroleum', 'hp', 'hindustan petroleum', 'reliance',
    'shell', 'essar', 'nayara', 'ev charging', 'electric vehicle'
  ],
  clothes: [
    'zara', 'h&m', 'uniqlo', 'levis', 'nike', 'adidas', 'puma', 'reebok',
    'pantaloons', 'westside', 'lifestyle', 'shoppers stop', 'max', 'fbb',
    'reliance trends', 'myntra', 'ajio', 'fashion', 'garments', 'textile',
    'cloth', 'shirt', 'pant', 'jeans', 'dress', 'saree', 'kurti', 'footwear',
    'shoes', 'sandals', 'boots', 'sneakers'
  ],
  education: [
    'school', 'college', 'university', 'tuition', 'coaching', 'classes',
    'institute', 'academy', 'course', 'certification', 'exam', 'fee',
    'books', 'stationery', 'notebook', 'pen', 'pencil', 'udemy', 'coursera',
    'unacademy', 'byjus', 'vedantu', 'physics wallah', 'library'
  ],
  health: [
    'hospital', 'clinic', 'doctor', 'medicine', 'pharmacy', 'medical',
    'apollo', 'fortis', 'max healthcare', 'aiims', 'medplus', 'netmeds',
    'pharmeasy', '1mg', 'healthkart', 'lab', 'diagnostic', 'test', 'scan',
    'xray', 'mri', 'ct scan', 'dental', 'eye care', 'optician', 'gym',
    'fitness', 'yoga', 'wellness', 'spa', 'therapy'
  ],
  hotel: [
    'hotel', 'resort', 'oyo', 'treebo', 'fab hotels', 'taj', 'oberoi',
    'marriott', 'hilton', 'hyatt', 'ihg', 'radisson', 'novotel', 'ibis',
    'airbnb', 'booking.com', 'makemytrip', 'goibibo', 'trivago', 'yatra',
    'hostel', 'guest house', 'lodge', 'accommodation', 'stay', 'room rent'
  ],
  fun: [
    'movie', 'cinema', 'pvr', 'inox', 'cinepolis', 'bookmyshow', 'netflix',
    'amazon prime', 'hotstar', 'disney', 'spotify', 'youtube', 'gaming',
    'playstation', 'xbox', 'steam', 'amusement', 'theme park', 'concert',
    'event', 'ticket', 'entertainment', 'club', 'disco', 'party'
  ],
  personal: [
    'salon', 'parlour', 'haircut', 'beauty', 'cosmetics', 'makeup', 'skincare',
    'perfume', 'grooming', 'nykaa', 'sephora', 'lakme', 'loreal', 'dove',
    'nivea', 'garnier', 'personal care', 'hygiene', 'soap', 'shampoo'
  ],
  pets: [
    'pet', 'dog', 'cat', 'bird', 'fish', 'pet shop', 'pet store', 'vet',
    'veterinary', 'animal', 'pet food', 'pedigree', 'whiskas', 'grooming'
  ],
  others: [
    'amazon', 'flipkart', 'meesho', 'snapdeal', 'ebay', 'alibaba', 'shopping',
    'mall', 'store', 'supermarket', 'bigbasket', 'grofers', 'blinkit',
    'zepto', 'instamart', 'dmart', 'reliance fresh', 'more', 'spar',
    'electronics', 'mobile', 'laptop', 'computer', 'appliance', 'furniture',
    'home decor', 'ikea', 'pepperfry', 'urban ladder', 'gift', 'recharge',
    'bill payment', 'electricity', 'water', 'rent', 'insurance', 'emi'
  ]
};

// Extract amount from OCR text
const extractAmount = (text) => {
  const lowerText = text.toLowerCase();
  
  // Priority 1 (HIGHEST): Look for "Total Rs", "Total RS", "TOTAL Rs" - most common in Indian bills
  const totalRsPatterns = [
    /total\s*rs\.?\s*[:\s]*[₹]?\s*([\d,]+(?:\.\d{2})?)/i,
    /total\s*rs\s*([\d,]+(?:\.\d{2})?)/i,
  ];
  
  for (const pattern of totalRsPatterns) {
    const match = text.match(pattern);
    if (match) {
      console.log('Found Total Rs:', match[1]);
      return parseFloat(match[1].replace(/,/g, ''));
    }
  }
  
  // Priority 2: Look for "Bill Total", "Bill Total (Rounded)", "Bill Amount"
  const billTotalPatterns = [
    /bill\s*total\s*(?:\(rounded\))?[:\s]*[₹$]?\s*([\d,]+(?:\.\d{2})?)/i,
    /bill\s*amount[:\s]*[₹$]?\s*([\d,]+(?:\.\d{2})?)/i,
    /bill\s*total\s*(?:\(rounded\))?[:\s]*(?:rs\.?|inr)?\s*([\d,]+(?:\.\d{2})?)/i,
  ];
  
  for (const pattern of billTotalPatterns) {
    const match = text.match(pattern);
    if (match) {
      console.log('Found Bill Total/Amount:', match[1]);
      return parseFloat(match[1].replace(/,/g, ''));
    }
  }
  
  // Priority 3: Look for "Grand Total", "Net Total", "Amount Payable", "Final Amount"
  const finalTotalPatterns = [
    /(?:grand\s*total|net\s*total|total\s*amount|net\s*amount|amount\s*payable|final\s*amount|amount\s*due)[:\s]*[₹$]?\s*([\d,]+(?:\.\d{2})?)/i,
    /(?:grand\s*total|net\s*total|total\s*amount|net\s*amount|amount\s*payable|final\s*amount|amount\s*due)[:\s]*(?:rs\.?|inr)?\s*([\d,]+(?:\.\d{2})?)/i,
  ];
  
  for (const pattern of finalTotalPatterns) {
    const match = lowerText.match(pattern);
    if (match) {
      console.log('Found final total:', match[1]);
      return parseFloat(match[1].replace(/,/g, ''));
    }
  }
  
  // Priority 4: Look for plain "Total" (but not "Subtotal" or "Sub Total")
  const totalPatterns = [
    /(?<!sub\s?)(?<!sub)total[:\s]*[₹$]?\s*([\d,]+(?:\.\d{2})?)/i,
    /(?<!sub\s?)(?<!sub)total[:\s]*(?:rs\.?|inr)?\s*([\d,]+(?:\.\d{2})?)/i,
  ];
  
  for (const pattern of totalPatterns) {
    const match = lowerText.match(pattern);
    if (match) {
      console.log('Found total:', match[1]);
      return parseFloat(match[1].replace(/,/g, ''));
    }
  }
  
  // Priority 5: Look for amounts near end of text (usually where total appears)
  const lines = text.split('\n').reverse(); // Start from bottom
  for (const line of lines.slice(0, 10)) { // Check last 10 lines
    const amountMatch = line.match(/[₹$]?\s*([\d,]+\.\d{2})/);
    if (amountMatch) {
      const amount = parseFloat(amountMatch[1].replace(/,/g, ''));
      if (amount > 10) { // Reasonable minimum for a bill total
        console.log('Found amount near end:', amount);
        return amount;
      }
    }
  }
  
  // Priority 6: Look for Subtotal only as last resort (before taxes)
  const subtotalMatch = lowerText.match(/sub\s*total[:\s]*[₹$]?\s*([\d,]+(?:\.\d{2})?)/i);
  if (subtotalMatch) {
    console.log('Found subtotal (fallback):', subtotalMatch[1]);
    return parseFloat(subtotalMatch[1].replace(/,/g, ''));
  }
  
  // Fallback: Find largest amount in the text (likely the total)
  const amounts = text.match(/[\d,]+\.\d{2}/g) || [];
  if (amounts.length > 0) {
    const numericAmounts = amounts.map(a => parseFloat(a.replace(/,/g, '')));
    return Math.max(...numericAmounts);
  }
  
  // Last resort: any number
  const numbers = text.match(/[\d,]+/g) || [];
  if (numbers.length > 0) {
    const numericNumbers = numbers.map(n => parseFloat(n.replace(/,/g, ''))).filter(n => n > 10);
    return numericNumbers.length > 0 ? Math.max(...numericNumbers) : null;
  }
  
  return null;
};

// Extract date from OCR text with improved accuracy
const extractDate = (text) => {
  const lowerText = text.toLowerCase();
  
  // First, try to find date near "date:", "dt:", "bill date:", "invoice date:"
  const dateLinePatterns = [
    /(?:bill\s*)?date\s*[:\-]?\s*(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})/i,
    /(?:bill\s*)?dt\s*[:\-]?\s*(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})/i,
    /(?:invoice\s*)?date\s*[:\-]?\s*(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})/i,
  ];
  
  for (const pattern of dateLinePatterns) {
    const match = text.match(pattern);
    if (match) {
      const day = match[1].padStart(2, '0');
      const month = match[2].padStart(2, '0');
      let year = match[3];
      if (year.length === 2) {
        year = '20' + year;
      }
      console.log('Found date near label:', `${year}-${month}-${day}`);
      return `${year}-${month}-${day}`;
    }
  }
  
  // Try DD-MMM-YYYY or DD MMM YYYY format
  const monthNames = {
    'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04', 'may': '05', 'jun': '06',
    'jul': '07', 'aug': '08', 'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12'
  };
  
  const monthPatterns = [
    /(\d{1,2})[\s\-]*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[\s\-,]*(\d{2,4})/i,
    /(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[\s\-]*(\d{1,2})[\s\-,]*(\d{2,4})/i,
  ];
  
  for (const pattern of monthPatterns) {
    const match = text.match(pattern);
    if (match) {
      let day, month, year;
      if (match[1].match(/\d+/)) {
        day = match[1].padStart(2, '0');
        month = monthNames[match[2].toLowerCase().substring(0, 3)];
        year = match[3];
      } else {
        month = monthNames[match[1].toLowerCase().substring(0, 3)];
        day = match[2].padStart(2, '0');
        year = match[3];
      }
      if (year.length === 2) {
        year = '20' + year;
      }
      console.log('Found month name date:', `${year}-${month}-${day}`);
      return `${year}-${month}-${day}`;
    }
  }
  
  // Generic date patterns
  const genericPatterns = [
    /(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})/,  // DD/MM/YYYY
    /(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})/,  // YYYY/MM/DD
    /(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2})/,  // DD/MM/YY
  ];
  
  for (const pattern of genericPatterns) {
    const match = text.match(pattern);
    if (match) {
      let year, month, day;
      if (match[1].length === 4) {
        // YYYY/MM/DD format
        year = match[1];
        month = match[2].padStart(2, '0');
        day = match[3].padStart(2, '0');
      } else {
        // DD/MM/YYYY or DD/MM/YY format
        day = match[1].padStart(2, '0');
        month = match[2].padStart(2, '0');
        year = match[3];
        if (year.length === 2) {
          year = '20' + year;
        }
      }
      console.log('Found generic date:', `${year}-${month}-${day}`);
      return `${year}-${month}-${day}`;
    }
  }
  
  return null;
};

// Categorize based on text content - uses LLM first, falls back to keywords
const categorizeText = async (text) => {
  // Try LLM categorization first
  const llmCategory = await categorizeWithLLM(text);
  if (llmCategory) {
    return { category: llmCategory, method: 'llm' };
  }
  
  // Fallback to keyword matching
  const lowerText = text.toLowerCase();
  
  // Special check for restaurant indicators (high priority)
  const restaurantIndicators = [
    'table no', 'table #', 'waiter', 'cover', 'kot', 'kitchen order',
    'dine in', 'dine-in', 'fssai', 'starter', 'main course', 'dessert',
    'veg', 'non-veg', 'non veg', 'paneer', 'biryani', 'roti', 'naan',
    'dal', 'curry', 'rice', 'thali', 'paratha', 'dosa', 'idli', 'sambar',
    'veg treat', 'foodlink', 'food link', 'kitchen', 'restaurant', 
    'cafe', 'dhaba', 'family restaurant', 'pure veg', 'multi cuisine'
  ];
  
  let restaurantScore = 0;
  for (const indicator of restaurantIndicators) {
    if (lowerText.includes(indicator)) {
      restaurantScore += 2;  // Give extra weight to restaurant indicators
    }
  }
  
  if (restaurantScore >= 4) {
    console.log('Detected as restaurant (score:', restaurantScore, ')');
    return { category: 'restaurants', method: 'keywords-restaurant' };
  }
  
  // Check each category for keyword matches
  const categoryScores = {};
  
  for (const [category, keywords] of Object.entries(categoryKeywords)) {
    categoryScores[category] = 0;
    for (const keyword of keywords) {
      if (lowerText.includes(keyword.toLowerCase())) {
        categoryScores[category]++;
      }
    }
  }
  
  // Add restaurant score
  categoryScores['restaurants'] = (categoryScores['restaurants'] || 0) + restaurantScore;
  
  // Find category with highest score
  let bestCategory = 'others';
  let maxScore = 0;
  
  for (const [category, score] of Object.entries(categoryScores)) {
    if (score > maxScore) {
      maxScore = score;
      bestCategory = category;
    }
  }
  
  return { category: bestCategory, method: 'keywords' };
};

// Extract merchant/vendor name with improved accuracy
const extractMerchant = (text) => {
  const lines = text.split('\n').filter(line => line.trim().length > 0);
  
  // Patterns to skip (addresses, IDs, dates, etc.)
  const skipPatterns = [
    /^\d+$/,  // Just numbers
    /^\d{2}[\/-]\d{2}[\/-]\d{2,4}/,  // Dates
    /^(tel|phone|mobile|fax|email|gstin|gst|fssai|address|date|time|invoice|bill\s*no)/i,
    /^(no\.|sr\.|#|\*)/i,  // List items
    /^\+?\d{10,}/,  // Phone numbers
    /^[A-Z]{2}\d{2}[A-Z]\d{4}/,  // GSTIN pattern
    /^(www\.|http)/i,  // URLs
    /^\d+[,\s]\w+/,  // Address starting with number
    /^(road|street|lane|nagar|colony|sector|block)/i,  // Address keywords
  ];
  
  // Look for merchant name in first 5 lines
  for (let i = 0; i < Math.min(5, lines.length); i++) {
    let line = lines[i].trim();
    
    // Skip very short or very long lines
    if (line.length < 3 || line.length > 40) continue;
    
    // Check against skip patterns
    let shouldSkip = false;
    for (const pattern of skipPatterns) {
      if (pattern.test(line)) {
        shouldSkip = true;
        break;
      }
    }
    if (shouldSkip) continue;
    
    // Clean up the line
    line = line
      .replace(/^[\*\-\=\#\|\[\]]+/, '')  // Remove leading symbols
      .replace(/[\*\-\=\#\|\[\]]+$/, '')  // Remove trailing symbols
      .replace(/\s+/g, ' ')  // Normalize spaces
      .trim();
    
    // Limit to max 30 characters for merchant name
    if (line.length > 30) {
      line = line.substring(0, 30).trim();
    }
    
    // Good candidate if it has mostly letters and spaces
    const letterRatio = (line.match(/[a-zA-Z]/g) || []).length / line.length;
    if (letterRatio > 0.5 && line.length >= 3 && line.length <= 30) {
      console.log('Found merchant:', line);
      return line;
    }
  }
  
  // Fallback: Look for lines with restaurant/business keywords
  const businessKeywords = ['restaurant', 'kitchen', 'cafe', 'hotel', 'dhaba', 'foods', 'mart', 'store', 'shop'];
  for (const line of lines.slice(0, 10)) {
    const lowerLine = line.toLowerCase();
    for (const keyword of businessKeywords) {
      if (lowerLine.includes(keyword)) {
        let merchant = line.trim();
        // Limit length
        if (merchant.length > 30) {
          merchant = merchant.substring(0, 30).trim();
        }
        console.log('Found merchant by keyword:', merchant);
        return merchant;
      }
    }
  }
  
  return null;
};

// Clean and limit extracted data for the response
const cleanExtractedData = (data) => {
  return {
    merchant: data.merchant ? data.merchant.substring(0, 30).trim() : null,
    amount: data.amount,
    category: data.category,
    date: data.date,
  };
};

// Process bill image using Tesseract.js
const processBill = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file uploaded'
      });
    }

    // Get the image buffer from multer
    const imageBuffer = req.file.buffer;
    
    // Perform OCR using Tesseract.js
    const result = await Tesseract.recognize(
      imageBuffer,
      'eng',
      {
        logger: m => console.log(m) // Optional: log progress
      }
    );

    const extractedText = result.data.text;
    
    // Extract information from the text
    const amount = extractAmount(extractedText);
    const categoryResult = await categorizeText(extractedText);
    const date = extractDate(extractedText);
    const merchant = extractMerchant(extractedText);

    return res.json({
      success: true,
      data: {
        rawText: extractedText,
        amount: amount,
        category: categoryResult.category,
        categoryMethod: categoryResult.method,
        date: date,
        merchant: merchant,
        confidence: result.data.confidence
      }
    });

  } catch (error) {
    console.error('Bill processing error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to process bill image',
      error: error.message
    });
  }
};

// Process bill from base64 string
const processBillBase64 = async (req, res) => {
  try {
    const { image } = req.body;
    
    if (!image) {
      return res.status(400).json({
        success: false,
        message: 'No image data provided'
      });
    }

    // Remove data URL prefix if present (handles various image formats)
    let base64Data = image;
    if (base64Data.includes('base64,')) {
      base64Data = base64Data.split('base64,')[1];
    } else {
      // Also try removing common data URL prefixes
      base64Data = base64Data.replace(/^data:image\/[a-zA-Z+]+;base64,/, '');
    }
    
    // Clean up any whitespace or newlines in base64 string
    base64Data = base64Data.replace(/[\s\n\r]/g, '');
    
    const imageBuffer = Buffer.from(base64Data, 'base64');
    
    // Validate that we have valid image data
    if (imageBuffer.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid image data - empty buffer'
      });
    }
    
    console.log(`Processing image: ${imageBuffer.length} bytes`);
    
    // Perform OCR using Tesseract.js with optimized settings
    const result = await Tesseract.recognize(
      imageBuffer,
      'eng',
      {
        logger: m => {
          if (m.status === 'recognizing text') {
            console.log(`OCR Progress: ${Math.round(m.progress * 100)}%`);
          }
        },
        // OCR Engine Mode: Use LSTM neural network for better accuracy
        tessedit_ocr_engine_mode: 2,
        // Page Segmentation Mode: Assume a single uniform block of text
        tessedit_pageseg_mode: 6,
        // Preserve interword spaces
        preserve_interword_spaces: 1,
      }
    );

    const extractedText = result.data.text;
    
    // Pre-process the OCR text
    const cleanedText = preprocessText(extractedText);
    console.log('OCR Extracted text (first 500 chars):', cleanedText.substring(0, 500));
    
    // Try LLM extraction first for better accuracy
    const llmData = await extractWithLLM(cleanedText);
    
    if (llmData) {
      // Use LLM-extracted data with fallback to regex extraction
      const finalAmount = llmData.amount || extractAmount(cleanedText);
      const finalMerchant = llmData.merchant || extractMerchant(cleanedText);
      const finalDate = llmData.date || extractDate(cleanedText);
      const finalCategory = llmData.category || 'others';
      
      console.log('Final extraction:', { amount: finalAmount, merchant: finalMerchant, date: finalDate, category: finalCategory });
      
      return res.json({
        success: true,
        data: {
          rawText: extractedText,
          amount: finalAmount,
          category: finalCategory,
          categoryMethod: 'llm',
          date: finalDate,
          merchant: finalMerchant,
          confidence: result.data.confidence
        }
      });
    }
    
    // Fallback to regex extraction if LLM fails
    console.log('LLM extraction failed, using regex fallback');
    const amount = extractAmount(cleanedText);
    const categoryResult = await categorizeText(cleanedText);
    const date = extractDate(cleanedText);
    const merchant = extractMerchant(cleanedText);
    
    console.log('Regex extraction:', { amount, merchant, date, category: categoryResult.category });

    return res.json({
      success: true,
      data: {
        rawText: extractedText,
        amount: amount,
        category: categoryResult.category,
        categoryMethod: categoryResult.method,
        date: date,
        merchant: merchant,
        confidence: result.data.confidence
      }
    });

  } catch (error) {
    console.error('Bill processing error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to process bill image',
      error: error.message
    });
  }
};

module.exports = {
  processBill,
  processBillBase64
};
