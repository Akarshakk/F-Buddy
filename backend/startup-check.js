/**
 * Startup Check Script
 * Verifies all required configurations before starting the server
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');

console.log('🔍 Running Backend Startup Checks...\n');

let hasErrors = false;

// Check 1: Environment Variables
console.log('1️⃣ Checking Environment Variables...');
const requiredEnvVars = ['PORT', 'JWT_SECRET'];
const missingEnvVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingEnvVars.length > 0) {
    console.error('   ❌ Missing required environment variables:', missingEnvVars.join(', '));
    hasErrors = true;
} else {
    console.log('   ✅ All required environment variables present');
    console.log(`   - PORT: ${process.env.PORT}`);
    console.log(`   - JWT_SECRET: ${process.env.JWT_SECRET.substring(0, 10)}...`);
}

// Check 2: Firebase Configuration (Optional for local development)
console.log('\n2️⃣ Checking Firebase Configuration...');
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
if (fs.existsSync(serviceAccountPath)) {
    console.log('   ✅ Firebase service account file found');
} else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    console.log('   ✅ Firebase configured via environment variables');
} else {
    console.log('   ⚠️  Firebase not configured - using local auth only');
    // hasErrors = true; // Commented out for local development
}

// Check 3: SMTP Configuration (Optional)
console.log('\n3️⃣ Checking SMTP Configuration (Optional)...');
if (process.env.SMTP_EMAIL && process.env.SMTP_PASSWORD) {
    console.log('   ✅ SMTP configured - OTP emails will be sent');
    console.log(`   - Email: ${process.env.SMTP_EMAIL}`);
} else {
    console.log('   ⚠️  SMTP not configured - OTPs will only appear in console');
}

// Check 4: Upload Directories
console.log('\n4️⃣ Checking Upload Directories...');
const uploadDirs = [
    'uploads',
    'uploads/kyc'
];

uploadDirs.forEach(dir => {
    const dirPath = path.join(__dirname, dir);
    if (!fs.existsSync(dirPath)) {
        console.log(`   📁 Creating directory: ${dir}`);
        fs.mkdirSync(dirPath, { recursive: true });
    }
});
console.log('   ✅ All upload directories ready');

// Check 5: Required Dependencies
console.log('\n5️⃣ Checking Dependencies...');
const requiredPackages = [
    'express',
    'firebase-admin',
    'jsonwebtoken',
    'bcryptjs',
    'multer',
    'tesseract.js',
    'nodemailer',
    'otp-generator',
    'cors',
    'dotenv'
];

const missingPackages = [];
requiredPackages.forEach(pkg => {
    try {
        require.resolve(pkg);
    } catch (e) {
        missingPackages.push(pkg);
    }
});

if (missingPackages.length > 0) {
    console.error('   ❌ Missing packages:', missingPackages.join(', '));
    console.error('   Run: npm install');
    hasErrors = true;
} else {
    console.log('   ✅ All required packages installed');
}

// Check 6: Tesseract Trained Data
console.log('\n6️⃣ Checking Tesseract OCR...');
const trainedDataPath = path.join(__dirname, 'eng.traineddata');
if (fs.existsSync(trainedDataPath)) {
    console.log('   ✅ Tesseract trained data found');
} else {
    console.log('   ⚠️  Tesseract trained data not found (will download on first use)');
}

// Summary
console.log('\n' + '='.repeat(50));
if (hasErrors) {
    console.error('❌ Startup checks failed! Please fix the errors above.');
    console.log('='.repeat(50));
    process.exit(1);
} else {
    console.log('✅ All checks passed! Server is ready to start.');
    console.log('='.repeat(50));
    console.log('\n💡 Tips:');
    console.log('   - Start server: npm start or npm run dev');
    console.log('   - Test KYC flow: node test-kyc-flow.js');

    console.log('\n🚀 Starting server...\n');
}
