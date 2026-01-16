const { getDb } = require('../config/firebase');
const { serializeDoc } = require('../utils/firestore');

const COLLECTION_NAME = 'debts';

const DEBT_TYPES = ['they_owe_me', 'i_owe'];

// Create debt
const create = async (debtData) => {
  const db = getDb();

  const debt = {
    user: debtData.user,
    type: DEBT_TYPES.includes(debtData.type) ? debtData.type : 'they_owe_me',
    amount: debtData.amount,
    personName: debtData.personName?.trim() || '',
    description: debtData.description?.trim() || '',
    dueDate: debtData.dueDate ? new Date(debtData.dueDate) : new Date(),
    isSettled: false,
    settledDate: null,
    reminderSent: false,
    createdAt: new Date()
  };

  const docRef = await db.collection(COLLECTION_NAME).add(debt);
  return { id: docRef.id, ...debt, dueDate: debt.dueDate.toISOString(), createdAt: debt.createdAt.toISOString() };
};

// Find debts by user
const findByUser = async (userId, options = {}) => {
  const db = getDb();
  let query = db.collection(COLLECTION_NAME).where('user', '==', userId);

  if (options.isSettled !== undefined) {
    query = query.where('isSettled', '==', options.isSettled);
  }

  if (options.type) {
    query = query.where('type', '==', options.type);
  }

  const snapshot = await query.get();
  return snapshot.docs.map(doc => serializeDoc(doc));
};

// Find debt by ID
const findById = async (id) => {
  const db = getDb();
  const doc = await db.collection(COLLECTION_NAME).doc(id).get();

  if (!doc.exists) return null;
  return serializeDoc(doc);
};

// Update debt
const updateById = async (id, updateData) => {
  const db = getDb();

  if (updateData.dueDate) {
    updateData.dueDate = new Date(updateData.dueDate);
  }

  await db.collection(COLLECTION_NAME).doc(id).update(updateData);
  return await findById(id);
};

// Delete debt
const deleteById = async (id) => {
  const db = getDb();
  await db.collection(COLLECTION_NAME).doc(id).delete();
  return true;
};

// Settle debt
const settle = async (id) => {
  const db = getDb();
  await db.collection(COLLECTION_NAME).doc(id).update({
    isSettled: true,
    settledDate: new Date()
  });
  return await findById(id);
};

// Get debts due today (for reminders)
const getDebtsDueToday = async () => {
  const db = getDb();
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const snapshot = await db.collection(COLLECTION_NAME)
    .where('dueDate', '>=', today)
    .where('dueDate', '<', tomorrow)
    .where('isSettled', '==', false)
    .where('reminderSent', '==', false)
    .get();

  // Populate user data
  const debts = [];
  for (const doc of snapshot.docs) {
    const debtData = { id: doc.id, ...doc.data() };
    const serializedDebt = serializeDoc({ data: () => debtData, id: doc.id }); // Use helper nicely or just map manual

    // Get user info
    const userDoc = await db.collection('users').doc(debtData.user).get();
    if (userDoc.exists) {
      // We don't need full serializeDoc here maybe? Just user object construction.
      serializedDebt.user = { id: userDoc.id, name: userDoc.data().name, email: userDoc.data().email };
    }
    debts.push(serializedDebt);
  }

  return debts;
};

module.exports = {
  COLLECTION_NAME,
  DEBT_TYPES,
  create,
  findByUser,
  findById,
  updateById,
  deleteById,
  settle,
  getDebtsDueToday
};
