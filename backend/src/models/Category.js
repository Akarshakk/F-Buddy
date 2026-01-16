const { getDb } = require('../config/firebase');

const COLLECTION_NAME = 'categories';

// Create category
const create = async (categoryData) => {
  const db = getDb();

  const category = {
    name: categoryData.name?.toLowerCase().trim() || '',
    displayName: categoryData.displayName || '',
    icon: categoryData.icon || '',
    color: categoryData.color || '',
    isActive: categoryData.isActive !== false
  };

  const docRef = await db.collection(COLLECTION_NAME).add(category);
  return { id: docRef.id, ...category };
};

// Find all categories
const findAll = async (activeOnly = true) => {
  const db = getDb();
  let query = db.collection(COLLECTION_NAME);

  if (activeOnly) {
    query = query.where('isActive', '==', true);
  }

  const snapshot = await query.get();
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// Find category by name
const findByName = async (name) => {
  const db = getDb();
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('name', '==', name.toLowerCase())
    .limit(1)
    .get();

  if (snapshot.empty) return null;
  const doc = snapshot.docs[0];
  return { id: doc.id, ...doc.data() };
};

// Find category by ID
const findById = async (id) => {
  const db = getDb();
  const doc = await db.collection(COLLECTION_NAME).doc(id).get();

  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
};

// Update category
const updateById = async (id, updateData) => {
  const db = getDb();
  await db.collection(COLLECTION_NAME).doc(id).update(updateData);
  return await findById(id);
};

module.exports = {
  COLLECTION_NAME,
  create,
  findAll,
  findByName,
  findById,
  updateById
};
