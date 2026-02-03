const { getDb } = require('../config/firebase');
const { serializeDoc } = require('../utils/firestore');

const COLLECTION_NAME = 'paper_trades';

// Paper Trade schema
const paperTradeFields = {
  userId: { type: 'string', required: true },
  symbol: { type: 'string', required: true },
  stockName: { type: 'string', required: true },
  type: { type: 'string', enum: ['BUY', 'SELL'], required: true },
  quantity: { type: 'number', required: true, min: 1 },
  price: { type: 'number', required: true },
  totalValue: { type: 'number', required: true },
  createdAt: { type: 'timestamp', default: () => new Date() }
};

// Create a new paper trade
const createTrade = async (tradeData) => {
  const db = getDb();
  
  const trade = {
    userId: tradeData.userId,
    symbol: tradeData.symbol.toUpperCase(),
    stockName: tradeData.stockName,
    type: tradeData.type,
    quantity: tradeData.quantity,
    price: tradeData.price,
    totalValue: tradeData.quantity * tradeData.price,
    createdAt: new Date()
  };

  const docRef = await db.collection(COLLECTION_NAME).add(trade);
  return { id: docRef.id, ...trade, createdAt: trade.createdAt.toISOString() };
};

// Get user's trade history
const getTradeHistory = async (userId, options = {}) => {
  const db = getDb();
  let query = db.collection(COLLECTION_NAME)
    .where('userId', '==', userId)
    .orderBy('createdAt', 'desc');

  if (options.limit) {
    query = query.limit(options.limit);
  }

  const snapshot = await query.get();
  return snapshot.docs.map(doc => serializeDoc(doc));
};

// Get trades for a specific stock
const getTradesBySymbol = async (userId, symbol) => {
  const db = getDb();
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('userId', '==', userId)
    .where('symbol', '==', symbol.toUpperCase())
    .orderBy('createdAt', 'desc')
    .get();

  return snapshot.docs.map(doc => serializeDoc(doc));
};

module.exports = {
  createTrade,
  getTradeHistory,
  getTradesBySymbol
};
