const { getDb } = require('../config/firebase');
const { serializeDoc } = require('../utils/firestore');

const COLLECTION_NAME = 'paper_portfolios';

// Default starting virtual balance
const DEFAULT_VIRTUAL_BALANCE = 100000; // ₹1,00,000

// Portfolio schema
const portfolioFields = {
  userId: { type: 'string', required: true, unique: true },
  virtualBalance: { type: 'number', default: DEFAULT_VIRTUAL_BALANCE },
  holdings: { type: 'array', default: [] }, // [{symbol, stockName, quantity, avgPrice}]
  totalInvested: { type: 'number', default: 0 },
  createdAt: { type: 'timestamp', default: () => new Date() },
  updatedAt: { type: 'timestamp', default: () => new Date() }
};

// Get or create portfolio for user
const getOrCreatePortfolio = async (userId) => {
  const db = getDb();

  // Try to find existing portfolio
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('userId', '==', userId)
    .limit(1)
    .get();

  if (!snapshot.empty) {
    return serializeDoc(snapshot.docs[0]);
  }

  // Create new portfolio
  const portfolio = {
    userId,
    virtualBalance: DEFAULT_VIRTUAL_BALANCE,
    holdings: [],
    totalInvested: 0,
    createdAt: new Date(),
    updatedAt: new Date()
  };

  const docRef = await db.collection(COLLECTION_NAME).add(portfolio);
  return {
    id: docRef.id,
    ...portfolio,
    createdAt: portfolio.createdAt.toISOString(),
    updatedAt: portfolio.updatedAt.toISOString()
  };
};

// Update portfolio after a trade
const updatePortfolio = async (userId, updates) => {
  const db = getDb();

  const snapshot = await db.collection(COLLECTION_NAME)
    .where('userId', '==', userId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw new Error('Portfolio not found');
  }

  const docRef = snapshot.docs[0].ref;
  await docRef.update({
    ...updates,
    updatedAt: new Date()
  });

  const updatedDoc = await docRef.get();
  return serializeDoc(updatedDoc);
};

// Execute a BUY trade
const executeBuyTrade = async (userId, symbol, stockName, quantity, price) => {
  const portfolio = await getOrCreatePortfolio(userId);
  const totalCost = quantity * price;

  // Check if user has enough balance
  if (portfolio.virtualBalance < totalCost) {
    throw new Error(`Insufficient virtual balance. Required: ₹${totalCost.toFixed(2)}, Available: ₹${portfolio.virtualBalance.toFixed(2)}`);
  }

  // Update holdings
  const holdings = [...(portfolio.holdings || [])];
  const existingHoldingIndex = holdings.findIndex(h => h.symbol === symbol.toUpperCase());

  if (existingHoldingIndex >= 0) {
    // Update existing holding with weighted average price
    const existing = holdings[existingHoldingIndex];
    const totalQuantity = existing.quantity + quantity;
    const avgPrice = ((existing.quantity * existing.avgPrice) + (quantity * price)) / totalQuantity;

    holdings[existingHoldingIndex] = {
      ...existing,
      quantity: totalQuantity,
      avgPrice: avgPrice
    };
  } else {
    // Add new holding
    holdings.push({
      symbol: symbol.toUpperCase(),
      stockName,
      quantity,
      avgPrice: price
    });
  }

  // Update portfolio
  const updates = {
    virtualBalance: portfolio.virtualBalance - totalCost,
    holdings,
    totalInvested: portfolio.totalInvested + totalCost
  };

  return await updatePortfolio(userId, updates);
};

// Execute a SELL trade
const executeSellTrade = async (userId, symbol, quantity, price) => {
  const portfolio = await getOrCreatePortfolio(userId);
  const holdings = [...(portfolio.holdings || [])];

  const holdingIndex = holdings.findIndex(h => h.symbol === symbol.toUpperCase());

  if (holdingIndex < 0) {
    throw new Error(`You don't own any shares of ${symbol}`);
  }

  const holding = holdings[holdingIndex];

  if (holding.quantity < quantity) {
    throw new Error(`Insufficient shares. You own ${holding.quantity} shares of ${symbol}`);
  }

  const saleValue = quantity * price;
  const costBasis = quantity * holding.avgPrice;

  // Update holdings
  if (holding.quantity === quantity) {
    // Remove holding completely
    holdings.splice(holdingIndex, 1);
  } else {
    // Reduce quantity (avgPrice stays the same)
    holdings[holdingIndex] = {
      ...holding,
      quantity: holding.quantity - quantity
    };
  }

  // Update portfolio
  const updates = {
    virtualBalance: portfolio.virtualBalance + saleValue,
    holdings,
    totalInvested: Math.max(0, portfolio.totalInvested - costBasis)
  };

  return await updatePortfolio(userId, updates);
};

// Reset portfolio to initial state
const resetPortfolio = async (userId) => {
  const db = getDb();

  const snapshot = await db.collection(COLLECTION_NAME)
    .where('userId', '==', userId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    return await getOrCreatePortfolio(userId);
  }

  const docRef = snapshot.docs[0].ref;
  const resetData = {
    virtualBalance: DEFAULT_VIRTUAL_BALANCE,
    holdings: [],
    totalInvested: 0,
    updatedAt: new Date()
  };

  await docRef.update(resetData);

  const updatedDoc = await docRef.get();
  return serializeDoc(updatedDoc);
};

module.exports = {
  DEFAULT_VIRTUAL_BALANCE,
  getOrCreatePortfolio,
  updatePortfolio,
  executeBuyTrade,
  executeSellTrade,
  resetPortfolio
};
