const { getDb } = require('../config/firebase');
const { serializeDoc } = require('../utils/firestore');

const COLLECTION_NAME = 'groupChats';

// Create a chat message
const create = async (messageData) => {
    const db = getDb();

    const message = {
        groupId: messageData.groupId,
        userId: messageData.userId,
        userName: messageData.userName,
        message: messageData.message?.trim() || '',
        timestamp: new Date()
    };

    const docRef = await db.collection(COLLECTION_NAME).add(message);
    return {
        id: docRef.id,
        ...message,
        timestamp: message.timestamp.toISOString()
    };
};

// Get messages by group ID - simplified to avoid composite index
const getByGroupId = async (groupId, limit = 50) => {
    const db = getDb();

    // Simple query with only one filter - no composite index needed
    const snapshot = await db.collection(COLLECTION_NAME)
        .where('groupId', '==', groupId)
        .get();

    // Sort in JavaScript instead of Firestore
    const messages = snapshot.docs
        .map(doc => serializeDoc(doc))
        .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

    // Return last N messages
    return messages.slice(-limit);
};

// Get messages after a certain timestamp (for polling) - simplified
const getNewMessages = async (groupId, after) => {
    const db = getDb();

    // Simple query with only one filter
    const snapshot = await db.collection(COLLECTION_NAME)
        .where('groupId', '==', groupId)
        .get();

    const afterDate = new Date(after);

    // Filter and sort in JavaScript
    return snapshot.docs
        .map(doc => serializeDoc(doc))
        .filter(msg => new Date(msg.timestamp) > afterDate)
        .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
};

module.exports = {
    create,
    getByGroupId,
    getNewMessages
};
