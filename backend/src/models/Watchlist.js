const { getDb } = require('../config/firebase');

const COLLECTION_NAME = 'watchlists';

// Helper to serialize Firestore documents
const serializeDoc = (doc) => {
  const data = doc.data();
  return {
    id: doc.id,
    ...data,
    createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt,
    updatedAt: data.updatedAt?.toDate?.()?.toISOString() || data.updatedAt
  };
};

// Get user's watchlist
const getWatchlist = async (userId) => {
  const db = getDb();
  
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('userId', '==', userId)
    .limit(1)
    .get();

  if (!snapshot.empty) {
    return serializeDoc(snapshot.docs[0]);
  }

  // Create empty watchlist if doesn't exist
  const watchlist = {
    userId,
    stocks: [], // Array of { symbol, stockName, addedAt }
    createdAt: new Date(),
    updatedAt: new Date()
  };

  const docRef = await db.collection(COLLECTION_NAME).add(watchlist);
  return { 
    id: docRef.id, 
    ...watchlist, 
    createdAt: watchlist.createdAt.toISOString(),
    updatedAt: watchlist.updatedAt.toISOString()
  };
};

// Add stock to watchlist
const addToWatchlist = async (userId, symbol, stockName) => {
  const db = getDb();
  const upperSymbol = symbol.toUpperCase();
  
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('userId', '==', userId)
    .limit(1)
    .get();

  let docRef;
  let stocks = [];

  if (snapshot.empty) {
    // Create new watchlist
    const watchlist = {
      userId,
      stocks: [{
        symbol: upperSymbol,
        stockName,
        addedAt: new Date().toISOString()
      }],
      createdAt: new Date(),
      updatedAt: new Date()
    };
    docRef = await db.collection(COLLECTION_NAME).add(watchlist);
    return { id: docRef.id, ...watchlist };
  }

  docRef = snapshot.docs[0].ref;
  const data = snapshot.docs[0].data();
  stocks = data.stocks || [];

  // Check if already in watchlist
  if (stocks.find(s => s.symbol === upperSymbol)) {
    throw new Error(`${symbol} is already in your watchlist`);
  }

  // Add to watchlist
  stocks.push({
    symbol: upperSymbol,
    stockName,
    addedAt: new Date().toISOString()
  });

  await docRef.update({
    stocks,
    updatedAt: new Date()
  });

  const updatedDoc = await docRef.get();
  return serializeDoc(updatedDoc);
};

// Remove stock from watchlist
const removeFromWatchlist = async (userId, symbol) => {
  const db = getDb();
  const upperSymbol = symbol.toUpperCase();
  
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('userId', '==', userId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw new Error('Watchlist not found');
  }

  const docRef = snapshot.docs[0].ref;
  const data = snapshot.docs[0].data();
  let stocks = data.stocks || [];

  // Check if stock exists in watchlist
  const stockIndex = stocks.findIndex(s => s.symbol === upperSymbol);
  if (stockIndex < 0) {
    throw new Error(`${symbol} is not in your watchlist`);
  }

  // Remove from watchlist
  stocks.splice(stockIndex, 1);

  await docRef.update({
    stocks,
    updatedAt: new Date()
  });

  const updatedDoc = await docRef.get();
  return serializeDoc(updatedDoc);
};

// Check if stock is in watchlist
const isInWatchlist = async (userId, symbol) => {
  const watchlist = await getWatchlist(userId);
  const upperSymbol = symbol.toUpperCase();
  return watchlist.stocks.some(s => s.symbol === upperSymbol);
};

module.exports = {
  getWatchlist,
  addToWatchlist,
  removeFromWatchlist,
  isInWatchlist
};
