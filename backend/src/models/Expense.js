const { getDb } = require('../config/firebase');
const { serializeDoc } = require('../utils/firestore');

const COLLECTION_NAME = 'expenses';

// Predefined categories for the app
const EXPENSE_CATEGORIES = [
  'clothes',
  'drinks',
  'education',
  'food',
  'fuel',
  'fun',
  'health',
  'hotel',
  'personal',
  'pets',
  'restaurants',
  'tips',
  'transport',
  'others'
];

// Create expense
const create = async (expenseData) => {
  const db = getDb();

  const expense = {
    user: expenseData.user,
    amount: expenseData.amount,
    category: expenseData.category?.toLowerCase() || 'others',
    description: expenseData.description?.trim() || '',
    merchant: expenseData.merchant?.trim() || '',
    date: expenseData.date ? new Date(expenseData.date) : new Date(),
    groupExpenseId: expenseData.groupExpenseId || null,
    groupId: expenseData.groupId || null,
    createdAt: new Date()
  };

  const docRef = await db.collection(COLLECTION_NAME).add(expense);
  // Return serialized
  return { id: docRef.id, ...expense, date: expense.date.toISOString(), createdAt: expense.createdAt.toISOString() };
};

// Find expenses by user with optional filters
const findByUser = async (userId, options = {}) => {
  const db = getDb();
  let query = db.collection(COLLECTION_NAME).where('user', '==', userId);

  // Apply date filters if provided
  if (options.startDate) {
    query = query.where('date', '>=', new Date(options.startDate));
  }
  if (options.endDate) {
    query = query.where('date', '<=', new Date(options.endDate));
  }

  // Apply category filter if provided
  if (options.category) {
    query = query.where('category', '==', options.category.toLowerCase());
  }

  // Sort by date descending by default (moved to JS)
  // query = query.orderBy('date', 'desc');

  // Apply limit if provided (Note: limiting before sorting is risky if database order undefined, 
  // but Firestore default order is usually ID/CreateTime? 
  // If we want correct "Top 5 recent", we MUST fetch all then sort then slice?
  // OR we keep orderBy ONLY if no complex filters?
  // User filter is simple.
  // If category filter present -> Composite required.
  // If Date range present (where date >= X) -> Composite? User+Date. Exists?
  // To be SAFE: fetch all matches, sort JS, slice JS. 
  // Expense lists are not huge usually.

  /*
  if (options.limit) {
    query = query.limit(options.limit);
  }
  */

  const snapshot = await query.get();
  let docs = snapshot.docs.map(doc => serializeDoc(doc));

  // Sort in memory
  docs.sort((a, b) => new Date(b.date) - new Date(a.date));

  // Apply limit in memory
  if (options.limit) {
    docs = docs.slice(0, options.limit);
  }
  return docs;
};

// Find expense by ID
const findById = async (id) => {
  const db = getDb();
  const doc = await db.collection(COLLECTION_NAME).doc(id).get();

  if (!doc.exists) return null;
  return serializeDoc(doc);
};

// Update expense
const updateById = async (id, updateData) => {
  const db = getDb();

  // Convert date if provided
  if (updateData.date) {
    updateData.date = new Date(updateData.date);
  }

  await db.collection(COLLECTION_NAME).doc(id).update(updateData);
  return await findById(id);
};

// Delete expense
const deleteById = async (id) => {
  const db = getDb();
  await db.collection(COLLECTION_NAME).doc(id).delete();
  return true;
};

// Delete by group link
const deleteByGroupLink = async (userId, groupId, groupExpenseId) => {
  const db = getDb();
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('user', '==', userId)
    .where('groupId', '==', groupId)
    .where('groupExpenseId', '==', groupExpenseId)
    .get();

  const batch = db.batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();

  return snapshot.size;
};

// Check for duplicate expense
const checkDuplicate = async (userId, amount, category, date, tolerance = 60000) => {
  const db = getDb();
  const targetDate = new Date(date);
  const startDate = new Date(targetDate.getTime() - tolerance);
  const endDate = new Date(targetDate.getTime() + tolerance);

  const snapshot = await db.collection(COLLECTION_NAME)
    .where('user', '==', userId)
    .where('amount', '==', amount)
    .where('category', '==', category.toLowerCase())
    .where('date', '>=', startDate)
    .where('date', '<=', endDate)
    .limit(1)
    .get();

  return !snapshot.empty;
};

// Aggregate expenses by category for a date range
const aggregateByCategory = async (userId, startDate, endDate) => {
  // Use findByUser to leverage existing serialization (or raw query if faster? findByUser is fine)
  // But wait, aggregateByCategory logic expects Objects. serializeDoc returns Objects with Strings.
  // JS string date comparison/math?
  // Logic: categoryMap[cat].totalAmount += expense.amount
  // Amount is number. access expense.category.
  // Safe.
  const expenses = await findByUser(userId, { startDate, endDate });

  const categoryMap = {};
  expenses.forEach(expense => {
    const cat = expense.category;
    if (!categoryMap[cat]) {
      categoryMap[cat] = { totalAmount: 0, count: 0 };
    }
    categoryMap[cat].totalAmount += expense.amount;
    categoryMap[cat].count += 1;
  });

  return Object.entries(categoryMap).map(([category, data]) => ({
    _id: category,
    totalAmount: data.totalAmount,
    count: data.count
  })).sort((a, b) => b.totalAmount - a.totalAmount);
};

// Get total expenses for a date range
const getTotalForRange = async (userId, startDate, endDate) => {
  const expenses = await findByUser(userId, { startDate, endDate });
  return expenses.reduce((sum, exp) => sum + exp.amount, 0);
};

// Get daily expenses for a date range (for charts)
const getDailyExpenses = async (userId, startDate, endDate) => {
  const expenses = await findByUser(userId, { startDate, endDate });

  const dailyMap = {};
  expenses.forEach(expense => {
    // expense.date is ISO String now because findByUser uses serializeDoc
    const date = new Date(expense.date); // Convert back for manipulation
    const key = `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
    if (!dailyMap[key]) {
      dailyMap[key] = { year: date.getFullYear(), month: date.getMonth() + 1, day: date.getDate(), totalExpense: 0 };
    }
    dailyMap[key].totalExpense += expense.amount;
  });

  return Object.values(dailyMap).sort((a, b) => {
    if (a.year !== b.year) return a.year - b.year;
    if (a.month !== b.month) return a.month - b.month;
    return a.day - b.day;
  });
};

// Get unique expense dates count
const getUniqueDatesCount = async (userId) => {
  const db = getDb();
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('user', '==', userId)
    .get();

  const uniqueDates = new Set();
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    // Raw data access, so it is Timestamp
    const date = data.date instanceof Date ? data.date : data.date.toDate();
    uniqueDates.add(`${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`);
  });

  return uniqueDates.size;
};

// Get categories
const getCategories = () => EXPENSE_CATEGORIES;

module.exports = {
  COLLECTION_NAME,
  EXPENSE_CATEGORIES,
  create,
  findByUser,
  findById,
  updateById,
  deleteById,
  deleteByGroupLink,
  checkDuplicate,
  aggregateByCategory,
  getTotalForRange,
  getDailyExpenses,
  getUniqueDatesCount,
  getCategories
};
