require('dotenv').config();
const { initializeFirebase, getDb } = require('./src/config/firebase');

const debugData = async () => {
    try {
        initializeFirebase();
        const db = getDb();

        // Target user email from your logs
        const targetEmail = 'tanna.at7@gmail.com';

        console.log(`🔍 inspecting data for: ${targetEmail}`);

        // 1. Find User
        const userSnapshot = await db.collection('users').where('email', '==', targetEmail).get();
        if (userSnapshot.empty) {
            console.log('❌ User not found!');
            return;
        }
        const userDoc = userSnapshot.docs[0];
        const user = { id: userDoc.id, ...userDoc.data() };
        console.log('✅ User Found:', user.id);
        console.log('   Email:', user.email);

        // 2. Check Groups
        console.log('\n--- GROUPS ---');
        const allGroups = await db.collection('groups').get();
        const userGroups = allGroups.docs.filter(doc => {
            const data = doc.data();
            return Array.isArray(data.members) && data.members.some(m => m.userId === user.id);
        });
        console.log(`Found ${userGroups.length} groups for user.`);
        userGroups.forEach(g => {
            console.log(` - ID: ${g.id}, Name: ${g.data().name}, Members: ${g.data().members.length}`);
            console.log(`   Internal Members:`, g.data().members.map(m => `${m.name} (${m.userId})`));
        });

        // 3. Check Incomes
        console.log('\n--- INCOMES ---');
        // Note: This query requires INDEX. If index missing, it might fail.
        // We try simple query first.
        try {
            const incomes = await db.collection('incomes').where('user', '==', user.id).get();
            console.log(`Found ${incomes.size} incomes.`);
            incomes.forEach(d => console.log(` - ${d.data().amount} - ${d.data().description} (${d.data().date?.toDate ? d.data().date.toDate().toISOString() : d.data().date})`));
        } catch (e) {
            console.log('❌ Error fetching incomes (Indexes?):', e.message);
        }

        // 4. Check Expenses
        console.log('\n--- EXPENSES ---');
        try {
            const expenses = await db.collection('expenses').where('user', '==', user.id).get();
            console.log(`Found ${expenses.size} expenses.`);
            expenses.forEach(d => console.log(` - ${d.data().amount} - ${d.data().category} (${d.data().date?.toDate ? d.data().date.toDate().toISOString() : d.data().date})`));
        } catch (e) {
            console.log('❌ Error fetching expenses (Indexes?):', e.message);
        }

    } catch (error) {
        console.error('❌ CRITICAL ERROR:', error);
    }
};

debugData();
