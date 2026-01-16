const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const initializeFirebase = () => {
    try {
        // Check if already initialized
        if (admin.apps.length > 0) {
            console.log('🔥 Firebase already initialized');
            return admin.firestore();
        }

        // Try to load service account from file
        const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');

        try {
            const serviceAccount = require(serviceAccountPath);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                projectId: serviceAccount.project_id
            });
            console.log(`🔥 Firebase initialized with project: ${serviceAccount.project_id}`);
        } catch (fileError) {
            // If file not found, try environment variables
            if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
                admin.initializeApp({
                    credential: admin.credential.cert({
                        projectId: process.env.FIREBASE_PROJECT_ID,
                        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
                    }),
                    projectId: process.env.FIREBASE_PROJECT_ID
                });
                console.log(`🔥 Firebase initialized with env vars for project: ${process.env.FIREBASE_PROJECT_ID}`);
            } else {
                throw new Error(
                    'Firebase credentials not found. Either:\n' +
                    '  1. Place firebase-service-account.json in backend/ folder, OR\n' +
                    '  2. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY env vars'
                );
            }
        }

        return admin.firestore();
    } catch (error) {
        console.error('❌ Error initializing Firebase:', error.message);
        console.log('⚠️  Firebase not configured - app will use MongoDB only');
        throw error; // Re-throw to be caught by server.js
    }
};

// Get Firestore instance
const getDb = () => {
    if (admin.apps.length === 0) {
        initializeFirebase();
    }
    return admin.firestore();
};

// Get Firebase Admin instance
const getAdmin = () => admin;

module.exports = { initializeFirebase, getDb, getAdmin };
