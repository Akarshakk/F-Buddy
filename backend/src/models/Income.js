const { getDb } = require('../config/firebase');
const { serializeDoc } = require('../utils/firestore');

const COLLECTION_NAME = 'incomes';

const INCOME_SOURCES = ['pocket_money', 'salary', 'freelance', 'gift', 'scholarship', 'other'];

// Create income
const create = async (incomeData) => {
  const db = getDb();

  const income = {
    user: incomeData.user,
    amount: incomeData.amount,
    description: incomeData.description?.trim() || 'Monthly Income',
    source: incomeData.source || 'pocket_money',
    month: incomeData.month,
    year: incomeData.year,
    date: incomeData.date ? new Date(incomeData.date) : new Date(),
    createdAt: new Date()
  };

  const docRef = await db.collection(COLLECTION_NAME).add(income);
  // Return serialized
  return { id: docRef.id, ...income, date: income.date.toISOString(), createdAt: income.createdAt.toISOString() };
};

// Find incomes by user
const findByUser = async (userId, options = {}) => {
  const db = getDb();
  let query = db.collection(COLLECTION_NAME).where('user', '==', userId);

  // Sort by date descending by default (moved to JS to avoid complex index requirements)
  // query = query.orderBy('date', 'desc'); 
  if (options.month) {
    query = query.where('month', '==', options.month);
  }
  if (options.year) {
    query = query.where('year', '==', options.year);
  }

  const snapshot = await query.get();
  const docs = snapshot.docs.map(doc => serializeDoc(doc));

  // Sort in memory
  return docs.sort((a, b) => new Date(b.date) - new Date(a.date));
};

// Find income by ID
const findById = async (id) => {
  const db = getDb();
  const doc = await db.collection(COLLECTION_NAME).doc(id).get();

  if (!doc.exists) return null;
  return serializeDoc(doc);
};

// Update income
const updateById = async (id, updateData) => {
  const db = getDb();

  if (updateData.date) {
    updateData.date = new Date(updateData.date);
  }

  await db.collection(COLLECTION_NAME).doc(id).update(updateData);
  return await findById(id);
};

// Delete income
const deleteById = async (id) => {
  const db = getDb();
  await db.collection(COLLECTION_NAME).doc(id).delete();
  return true;
};

// Get total income for month/year
const getTotalForMonth = async (userId, month, year) => {
  const incomes = await findByUser(userId, { month, year });
  return incomes.reduce((sum, inc) => sum + inc.amount, 0);
};

// Get total income for date range
const getTotalForRange = async (userId, startDate, endDate) => {
  const db = getDb();
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('user', '==', userId)
    .where('date', '>=', startDate)
    .where('date', '<=', endDate)
    .get();

  // Here we use raw data for speed/aggregation
  return snapshot.docs.reduce((sum, doc) => sum + doc.data().amount, 0);
};

// Get daily income for charts
const getDailyIncome = async (userId, startDate, endDate) => {
  const db = getDb();
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('user', '==', userId)
    .where('date', '>=', startDate)
    .where('date', '<=', endDate)
    .get();

  const dailyMap = {};
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    // Raw timestamp manipulation
    const date = data.date instanceof Date ? data.date : data.date.toDate();
    const key = `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
    if (!dailyMap[key]) {
      dailyMap[key] = { year: date.getFullYear(), month: date.getMonth() + 1, day: date.getDate(), totalIncome: 0 };
    }
    dailyMap[key].totalIncome += data.amount;
  });

  return Object.values(dailyMap).sort((a, b) => {
    if (a.year !== b.year) return a.year - b.year;
    if (a.month !== b.month) return a.month - b.month;
    return a.day - b.day;
  });
};

module.exports = {
  COLLECTION_NAME,
  INCOME_SOURCES,
  create,
  findByUser,
  findById,
  updateById,
  deleteById,
  getTotalForMonth,
  getTotalForRange,
  getDailyIncome
};
