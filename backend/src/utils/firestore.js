const serializeDoc = (doc) => {
    if (!doc.exists && !doc.data) return null;
    const data = doc.data ? doc.data() : doc;
    const id = doc.id ? doc.id : undefined;

    return convertTimestamps({ id, ...data });
};

const convertTimestamps = (obj) => {
    if (obj === null || typeof obj !== 'object') return obj;

    // Handle Firestore Timestamp
    if (obj.toDate && typeof obj.toDate === 'function') {
        return obj.toDate().toISOString();
    }

    // Handle native Date
    if (obj instanceof Date) {
        return obj.toISOString();
    }

    // Handle Arrays
    if (Array.isArray(obj)) {
        return obj.map(item => convertTimestamps(item));
    }

    // Handle Objects
    const newObj = {};
    for (const key in obj) {
        newObj[key] = convertTimestamps(obj[key]);
    }
    return newObj;
};

module.exports = { serializeDoc, convertTimestamps };
