require('dotenv').config({ path: '.env' });
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function listModels() {
    try {
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
        // Note: listModels is not directly exposed on genAI instance in some versions,
        // but we can try to infer or just test specific ones.
        // Actually, for the Node SDK, it's often ModelService via a different import or manually.
        // Let's try a direct test of common models instead of listing (which can be complex in SDK).

        const modelsToTest = [
            'gemini-2.0-flash',
            'gemini-2.0-flash-exp',
            'gemini-1.5-flash-002',
            'gemini-1.5-pro-002',
            'gemini-1.5-flash-8b'
        ];

        console.log('Testing models with API Key ending in:', process.env.GEMINI_API_KEY?.slice(-4));

        for (const modelName of modelsToTest) {
            process.stdout.write(`Testing ${modelName}... `);
            try {
                const model = genAI.getGenerativeModel({ model: modelName });
                const result = await model.generateContent('Hi');
                console.log('✅ SUCCESS');
            } catch (error) {
                if (error.message.includes('404')) {
                    console.log('❌ 404 NOT FOUND');
                } else if (error.message.includes('429')) {
                    console.log('⚠️ 429 RATE LIMIT (Exists but Busy)');
                } else {
                    console.log(`❌ ERROR: ${error.message.split('\n')[0]}`);
                }
            }
        }

    } catch (e) {
        console.error('Fatal Error:', e);
    }
}

listModels();
