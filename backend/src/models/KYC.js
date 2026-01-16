const { getDb } = require('../config/firebase');
const { serializeDoc } = require('../utils/firestore');

const COLLECTION_NAME = 'kyc';

const DOCUMENT_TYPES = ['aadhaar', 'pan', 'passport', 'driving_license'];
const VERIFICATION_STEPS = ['document_upload', 'selfie_verification', 'mfa_verification'];
const VERIFICATION_STATUSES = ['success', 'failed'];

// Create or get KYC record for user
const createOrGet = async (userId) => {
    const db = getDb();

    // Check if KYC exists for user
    const existing = await findByUser(userId);
    if (existing) return existing;

    const kyc = {
        user: userId,
        documentType: null,
        documentNumber: null,
        documentImage: null,
        ocrData: null,
        selfieImage: null,
        faceMatchScore: null,
        verificationHistory: [],
        createdAt: new Date(),
        updatedAt: new Date()
    };

    const docRef = await db.collection(COLLECTION_NAME).add(kyc);
    return { id: docRef.id, ...kyc, createdAt: kyc.createdAt.toISOString(), updatedAt: kyc.updatedAt.toISOString() };
};

// Find KYC by user
const findByUser = async (userId) => {
    const db = getDb();
    const snapshot = await db.collection(COLLECTION_NAME)
        .where('user', '==', userId)
        .limit(1)
        .get();

    if (snapshot.empty) return null;
    return serializeDoc(snapshot.docs[0]);
};

// Find KYC by ID
const findById = async (id) => {
    const db = getDb();
    const doc = await db.collection(COLLECTION_NAME).doc(id).get();

    if (!doc.exists) return null;
    return serializeDoc(doc);
};

// Update KYC
const updateById = async (id, updateData) => {
    const db = getDb();
    updateData.updatedAt = new Date();
    await db.collection(COLLECTION_NAME).doc(id).update(updateData);
    return await findById(id);
};

// Update KYC by user
const updateByUser = async (userId, updateData) => {
    const kyc = await findByUser(userId);
    if (!kyc) return null; // Or create? Original didn't create.
    return await updateById(kyc.id, updateData);
};

// Add verification history entry
const addVerificationHistory = async (userId, step, status, message) => {
    const kyc = await findByUser(userId);
    if (!kyc) return null;

    const historyEntry = {
        step,
        status,
        message,
        timestamp: new Date()
    };

    const history = kyc.verificationHistory || [];
    history.push(historyEntry);

    return await updateById(kyc.id, { verificationHistory: history });
};

// Update document info
const updateDocument = async (userId, documentType, documentImage, ocrData = null) => {
    let kyc = await findByUser(userId);
    if (!kyc) {
        kyc = await createOrGet(userId);
    }

    // Build ocrData object, converting undefined to null (Firestore doesn't accept undefined)
    let ocrDataClean = null;
    if (ocrData) {
        ocrDataClean = {
            rawText: ocrData.rawText || null,
            extractedName: ocrData.extractedName || null,
            extractedDob: ocrData.extractedDob || null,
            confidence: ocrData.confidence || null,
            verifiedAt: new Date()
        };
    }

    return await updateById(kyc.id, {
        documentType,
        documentImage,
        ocrData: ocrDataClean
    });
    // Note: updateById calls findById, which uses serializeDoc. 
    // So returned object has ISO strings for verifiedAt.
};

// Update selfie info
const updateSelfie = async (userId, selfieImage, faceMatchScore) => {
    // updateByUser calls updateById, which calls findById(serialized).
    return await updateByUser(userId, {
        selfieImage,
        faceMatchScore
    });
};

module.exports = {
    COLLECTION_NAME,
    DOCUMENT_TYPES,
    VERIFICATION_STEPS,
    VERIFICATION_STATUSES,
    createOrGet,
    findByUser,
    findById,
    updateById,
    updateByUser,
    addVerificationHistory,
    updateDocument,
    updateSelfie
};
