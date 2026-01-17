# 🚀 F-Buddy App - Complete Setup & Run Guide

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [First Time Setup](#first-time-setup)
3. [Running the App](#running-the-app)
4. [Testing Features](#testing-features)
5. [Troubleshooting](#troubleshooting)

---

## ✅ Prerequisites

### Required Software:
- ✅ Node.js (v14 or higher)
- ✅ Flutter SDK (v3.32.4)
- ✅ Android Studio
- ✅ Physical Android Phone (connected via USB)
- ✅ Git

### Required Accounts:
- ✅ Firebase Account (for backend)
- ✅ Gmail Account (for OTP emails)

---

## 🔧 First Time Setup

### Step 1: Clone the Repository
```bash
git clone <your-repo-url>
cd F-Buddy
```

### Step 2: Backend Setup

#### 2.1 Install Dependencies
```bash
cd backend
npm install
```

#### 2.2 Configure Environment Variables
Create `.env` file in `backend/` folder:
```env
PORT=5001
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
FIREBASE_PROJECT_ID=your_firebase_project_id

# Email Configuration (Gmail SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=tanna.at7@gmail.com
SMTP_PASS=erkhvdtibvadmxxc
```

#### 2.3 Add Firebase Service Account
Place `firebase-service-account.json` in `backend/` folder

### Step 3: Mobile App Setup

#### 3.1 Install Dependencies
```bash
cd mobile
flutter pub get
```

#### 3.2 Configure Backend IP
Edit `mobile/lib/config/constants.dart`:
```dart
static const String baseUrl = 'http://192.168.0.105:5001/api';
```
**Replace `192.168.0.105` with your computer's IP address**

#### 3.3 Connect Your Phone
1. Enable **Developer Options** on your Android phone
2. Enable **USB Debugging**
3. Connect phone via USB cable
4. Verify connection:
```bash
flutter devices
```

---

## ▶️ Running the App

### Method 1: Using Batch Files (Easiest)

#### Step 1: Start Backend
Double-click: `start-backend.bat`

OR manually:
```bash
cd backend
node src/server.js
```

**Expected Output:**
```
✅ Server running on port 5001
✅ MongoDB connected
✅ Firebase initialized
```

#### Step 2: Start Mobile App
Double-click: `start-frontend-android.bat`

OR manually:
```bash
cd mobile
flutter run -d <device-id>
```

**Expected Output:**
```
✅ Built build\app\outputs\flutter-apk\app-debug.apk
✅ Installing on RMX3998...
✅ App launched successfully
```

### Method 2: Using Command Line

#### Terminal 1 - Backend:
```bash
cd backend
node src/server.js
```

#### Terminal 2 - Mobile App:
```bash
cd mobile
flutter run
```

---

## 🧪 Testing Features

### 1. User Registration & Login
1. Open app on phone
2. Click **"Sign Up"**
3. Enter email and password
4. Check email for OTP (also logged in backend console)
5. Enter OTP to verify
6. Login with credentials

### 2. KYC Verification
1. Go to **Profile** → **Complete KYC**
2. Upload **Aadhaar Card** (front & back)
3. Upload **PAN Card**
4. Take **Selfie**
5. Enter phone number
6. Verify OTP (check email)
7. Wait for verification

### 3. SMS Auto-Tracking
1. Go to **Profile** → **SMS Auto-Tracking**
2. Enable SMS tracking
3. Grant SMS permissions
4. App will automatically detect banking SMS

#### Test SMS Filtering:
1. Click **"Debug: Banking SMS Only"**
2. View filtered banking/payment SMS
3. Verify no Jio service messages appear

#### Send Test SMS:
Send yourself: `TEST: Debited Rs 100 for Coffee`
Wait 15 seconds, transaction should appear in app

### 4. Manual Expense Entry
1. Go to **Dashboard** tab
2. Click **"+"** button
3. Select **Expense**
4. Enter amount, category, description
5. Save

### 5. Balance & Analytics
1. Go to **Dashboard** tab
2. View current balance
3. Check expense breakdown
4. View charts and trends

### 6. Finance Manager (Calculators)
1. Go to **Feature Selection** screen
2. Select **Finance Manager**
3. Try calculators:
   - EMI Calculator
   - SIP Calculator
   - Retirement Planner
   - Health Insurance
   - Emergency Fund

---

## 🔍 Troubleshooting

### Backend Issues

#### Problem: Port 5001 already in use
```bash
# Windows
netstat -ano | findstr :5001
taskkill /PID <process-id> /F
```

#### Problem: MongoDB connection failed
- Check MongoDB URI in `.env`
- Ensure MongoDB is running
- Check internet connection

#### Problem: Firebase error
- Verify `firebase-service-account.json` exists
- Check Firebase project ID in `.env`

### Mobile App Issues

#### Problem: App not installing
```bash
# Clean and rebuild
cd mobile
flutter clean
flutter pub get
flutter run
```

#### Problem: Backend connection failed
1. Check computer IP address:
```bash
ipconfig
```
2. Update `mobile/lib/config/constants.dart` with correct IP
3. Ensure phone and computer on same WiFi network

#### Problem: SMS not detecting
1. Grant SMS permissions: Settings → Apps → F-Buddy → Permissions → SMS
2. Check SMS polling is enabled in app
3. View logs:
```bash
flutter logs
```

#### Problem: Balance showing ₹0
1. Check backend is running
2. Verify API connection
3. Add test expense manually
4. Refresh dashboard

### Build Issues

#### Problem: Gradle build failed
```bash
cd mobile/android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

#### Problem: Dependency conflicts
```bash
cd mobile
flutter pub upgrade
flutter pub get
```

---

## 📱 Quick Commands Reference

### Backend Commands:
```bash
# Start backend
cd backend
node src/server.js

# Test backend
node verify-backend.js

# Check SMS parser
node test-sms-parser.js
```

### Mobile Commands:
```bash
# Run on connected device
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload (while running)
Press 'r' in terminal

# Hot restart (while running)
Press 'R' in terminal

# View logs
flutter logs

# Check devices
flutter devices

# Clean build
flutter clean
flutter pub get
```

### Git Commands:
```bash
# Pull latest changes
git pull origin main

# Check status
git status

# Commit changes
git add .
git commit -m "Your message"
git push origin main
```

---

## 🎯 Development Workflow

### Daily Development:
1. **Pull latest code**: `git pull origin main`
2. **Start backend**: `cd backend && node src/server.js`
3. **Start app**: `cd mobile && flutter run`
4. **Make changes** and hot reload with `r`
5. **Test features** on physical device
6. **Commit changes**: `git add . && git commit -m "message" && git push`

### Testing New Features:
1. Test on physical device (not emulator)
2. Check backend logs for errors
3. Use debug features (SMS debug button)
4. Verify balance updates correctly
5. Test with real SMS messages

---

## 📞 Support

### Check Logs:
- **Backend**: Terminal running `node src/server.js`
- **Mobile**: Terminal running `flutter run` or `flutter logs`
- **Android**: `adb logcat | grep flutter`

### Common Files to Check:
- Backend config: `backend/.env`
- Mobile config: `mobile/lib/config/constants.dart`
- SMS service: `mobile/lib/services/sms_service.dart`
- API service: `mobile/lib/services/api_service.dart`

---

## ✨ Features Summary

### ✅ Implemented Features:
- User Authentication (Email + OTP)
- KYC Verification (Aadhaar, PAN, Selfie, Face Match)
- SMS Auto-Tracking (Banking/UPI only)
- Manual Expense/Income Entry
- Real-time Balance Calculation
- Analytics Dashboard
- Finance Calculators (EMI, SIP, etc.)
- Debt Management
- Group Expense Splitting

### 🔒 Security Features:
- JWT Authentication
- Firebase Integration
- Face Verification
- OTP Verification (Email)
- Secure Storage

---

## 🎉 You're Ready!

Your F-Buddy app is now set up and ready to use. Follow the steps above to run the app and test all features.

**Quick Start:**
1. Run `start-backend.bat`
2. Run `start-frontend-android.bat`
3. Open app on phone
4. Start tracking your finances! 💰
