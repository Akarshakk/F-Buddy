const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const BASE_URL = 'http://localhost:5001/api';

async function runTest() {
    console.log('🧪 Testing Group Flow...');

    try {
        require('dotenv').config();

        // 1. Setup Auth (Create user)
        if (!admin.apps.length) {
            const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
            if (fs.existsSync(serviceAccountPath)) {
                const serviceAccount = require(serviceAccountPath);
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount),
                    projectId: serviceAccount.project_id
                });
            }
        }

        const db = admin.firestore();
        const email = `group_test_${Date.now()}@test.com`;

        const userRef = await db.collection('users').add({
            name: 'Group Tester',
            email: email,
            emailVerified: true,
            createdAt: new Date().toISOString()
        });

        const token = jwt.sign({ id: userRef.id }, process.env.JWT_SECRET, { expiresIn: '1d' });

        console.log(`✅ Created User: ${userRef.id}`);

        // 2. Create Group
        console.log('\n2️⃣ Creating Group...');
        const createRes = await fetch(`${BASE_URL}/groups`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify({
                name: 'Test Group',
                description: 'For testing'
            })
        });

        const createData = await createRes.json();

        if (!createData.success) {
            console.error('❌ Create Group Failed:', createData);
            return;
        }

        const groupId = createData.data.group.id;
        console.log(`✅ Group Created: ${groupId}`);
        console.log('Response format sample:', JSON.stringify(createData.data.group, null, 2));

        // 3. Add Member (Need another user)
        const email2 = `member_${Date.now()}@test.com`;
        const user2Ref = await db.collection('users').add({
            name: 'Member Two',
            email: email2,
            emailVerified: true
        });

        console.log('\n3️⃣ Adding Member...');
        const addRes = await fetch(`${BASE_URL}/groups/${groupId}/members`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify({
                memberEmail: email2
            })
        });

        const addData = await addRes.json();

        if (addData.success) {
            console.log('✅ Member Added!');
            console.log('Updated Members:', JSON.stringify(addData.data.group.members, null, 2));
        } else {
            console.error('❌ Add Member Failed:', addData);
        }

        // Cleanup
        await db.collection('users').doc(userRef.id).delete();
        await db.collection('users').doc(user2Ref.id).delete();
        await db.collection('groups').doc(groupId).delete();

    } catch (e) {
        console.error('❌ Error:', e);
    }
}

runTest();
