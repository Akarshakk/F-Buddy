require('dotenv').config();
const { initializeFirebase, getDb } = require('./src/config/firebase');
const Group = require('./src/models/Group');

const checkGroups = async () => {
    try {
        initializeFirebase();

        // IDs from previous debug logs
        const userA = 'QqM3FCy78eHAOJ1JHi0H'; // Owner/Tanna
        const userB = '2n68CNNekUWzkK43jZNz'; // Member

        console.log(`🔍 Checking groups for User A: ${userA}`);
        const groupsA = await Group.findByMember(userA);
        console.log(`Found ${groupsA.length} groups.`);
        groupsA.forEach(g => console.log(` - ${g.name} (${g.id}) | Members: ${g.members.length}`));

        console.log(`\n🔍 Checking groups for User B: ${userB}`);
        const groupsB = await Group.findByMember(userB);
        console.log(`Found ${groupsB.length} groups.`);
        groupsB.forEach(g => console.log(` - ${g.name} (${g.id}) | Members: ${g.members.length}`));

        // Check intersection
        const shared = groupsA.filter(gA => groupsB.some(gB => gB.id === gA.id));
        console.log(`\n✅ Shared Groups found: ${shared.length} (Expected at least 1)`);

    } catch (e) {
        console.error('ERROR:', e);
    }
};

checkGroups();
