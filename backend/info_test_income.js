const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Should use native fetch (Node 18+)
const BASE_URL = 'http://localhost:5001/api';

async function runTest() {
    console.log('🧪 Testing Income Persistence (using fetch)...');

    try {
        // 1. Setup Auth (Create user directly in DB)
        require('dotenv').config();

        // Initialize Firebase
        if (!admin.apps.length) {
            const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
            if (fs.existsSync(serviceAccountPath)) {
                const serviceAccount = require(serviceAccountPath);
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount),
                    projectId: serviceAccount.project_id
                });
            } else {
                console.error("❌ No service account file found!");
                return;
            }
        }

        const db = admin.firestore();
        const verifyUserEmail = `auto_test_${Date.now()}@test.com`;

        const userRef = await db.collection('users').add({
            name: 'Auto Tester',
            email: verifyUserEmail,
            emailVerified: true,
            createdAt: new Date().toISOString()
        });

        const token = jwt.sign({ id: userRef.id }, process.env.JWT_SECRET, { expiresIn: '1d' });

        console.log(`✅ Created Test User: ${userRef.id}`);

        // 2. Add Income via API
        console.log('\n2️⃣ Adding Income...');
        const addRes = await fetch(`${BASE_URL}/income`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                amount: 5000,
                description: 'Test Salary',
                source: 'salary',
                date: new Date().toISOString()
            })
        });

        const addData = await addRes.json();

        if (addData.success) {
            console.log('✅ Income Added via API!');
        } else {
            console.error('❌ Failed to add income:', addData);
            return;
        }

        // 3. Fetch Income via API
        console.log('\n3️⃣ Fetching Income...');
        const fetchRes = await fetch(`${BASE_URL}/income`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        const fetchData = await fetchRes.json();

        if (!fetchData.success) {
            console.error('❌ Failed to fetch income:', fetchData);
            return;
        }

        const incomes = fetchData.data.incomes;
        console.log(`📊 Found ${incomes.length} incomes`);

        const match = incomes.find(i => i.description === 'Test Salary' && i.amount === 5000);

        if (match) {
            console.log('✅ PERSISTENCE CONFIRMED: Created income was retrieved!');
            console.log('User ID used:', userRef.id);
            console.log('Income User ID:', match.user);
        } else {
            console.log('❌ PERSISTENCE FAILED: Could not find the created income.');
            console.log('Returned data:', JSON.stringify(incomes, null, 2));
        }

        // Clean up
        await db.collection('users').doc(userRef.id).delete();
        // Maybe delete income too for cleanliness, but fine for now.

    } catch (e) {
        console.error('❌ Error:', e.message);
        if (e.cause) console.error(e.cause);
    }
}

runTest();
