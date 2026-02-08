const { getDb } = require('../config/firebase');
const { serializeDoc } = require('../utils/firestore');

const COLLECTION_NAME = 'pending_orders';

// Create a new pending order
const createPendingOrder = async (orderData) => {
    const db = getDb();

    const order = {
        ...orderData,
        status: 'PENDING',
        createdAt: new Date()
    };

    const docRef = await db.collection(COLLECTION_NAME).add(order);
    return {
        id: docRef.id,
        ...order,
        createdAt: order.createdAt.toISOString()
    };
};

// Get pending orders for a user
const getPendingOrders = async (userId) => {
    const db = getDb();

    const snapshot = await db.collection(COLLECTION_NAME)
        .where('user', '==', userId)
        .where('status', '==', 'PENDING')
        .get();

    if (snapshot.empty) {
        return [];
    }

    const orders = snapshot.docs.map(doc => serializeDoc(doc));

    // Sort in memory (descending by createdAt)
    return orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
};

// Update order status (e.g. to EXECUTED or FAILED)
const updateOrderStatus = async (orderId, status, updates = {}) => {
    const db = getDb();
    const docRef = db.collection(COLLECTION_NAME).doc(orderId);

    await docRef.update({
        status,
        ...updates,
        updatedAt: new Date()
    });

    const updatedDoc = await docRef.get();
    return serializeDoc(updatedDoc);
};

module.exports = {
    createPendingOrder,
    getPendingOrders,
    updateOrderStatus
};
