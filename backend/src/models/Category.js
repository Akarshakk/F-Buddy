const { getDb } = require('../config/firebase');
const { serializeDoc } = require('../utils/firestore');

const COLLECTION_NAME = 'categories';

// Create category
const create = async (categoryData) => {
  const db = getDb();

  const category = {
    name: categoryData.name?.toLowerCase().trim() || '',
    displayName: categoryData.displayName || '',
    icon: categoryData.icon || '',
    color: categoryData.color || '',
    isActive: categoryData.isActive !== false,
    createdAt: new Date()
  };

  const docRef = await db.collection(COLLECTION_NAME).add(category);
  // Manual serialize since we have Date object here
  return { id: docRef.id, ...category, createdAt: category.createdAt.toISOString() };
};

// Find all categories
const findAll = async (activeOnly = true) => {
  const db = getDb();
  let query = db.collection(COLLECTION_NAME);

  if (activeOnly) {
    query = query.where('isActive', '==', true);
  }

  const snapshot = await query.get();
  return snapshot.docs.map(doc => serializeDoc(doc));
};

// Find category by name
const findByName = async (name) => {
  const db = getDb();
  const snapshot = await db.collection(COLLECTION_NAME)
    .where('name', '==', name.toLowerCase())
    .limit(1)
    .get();

  if (snapshot.empty) return null;
  return serializeDoc(snapshot.docs[0]);
};

// Find category by ID
const findById = async (id) => {
  const db = getDb();
  const doc = await db.collection(COLLECTION_NAME).doc(id).get();

  if (!doc.exists) return null;
  return serializeDoc(doc);
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
