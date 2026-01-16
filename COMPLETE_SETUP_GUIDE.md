# F-Buddy Complete Setup & Running Guide

## 🎯 Quick Start (For Physical Android Device)

### Prerequisites
- ✅ Node.js installed
- ✅ Flutter installed
- ✅ MongoDB running locally
- ✅ Android phone connected via USB
- ✅ Phone and computer on same WiFi network

---

## 📱 Step 1: Start Backend Server

### Option A: Using Batch File (Recommended)
```cmd
start-backend.bat
```

### Option B: Manual Start
```cmd
cd backend
npm install
node src/server.js
```

### ✅ Verify Backend is Running
- Open browser: http://localhost:5001/api/health
- Should see: `{"status":"OK","message":"F Buddy API is running!"}`
- Backend logs should show: `🚀 F Buddy Server running on port 5001`

### 📧 Email Configuration (ENABLED)
- **SMTP Email**: tanna.at7@gmail.com
- **OTP Delivery**: Sent via email + logged to console
- **Email Template**: Professional branded email
- **Fallback**: Console OTP if email fails

---

## 📲 Step 2: Configure Frontend for Physical Device

### Find Your Computer's IP Address
```cmd
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter (e.g., `192.168.0.105`)

### Update Frontend Configuration
File: `mobile/lib/config/constants.dart`

Change this line:
```dart
static const String _serverIp = 'localhost';
```

To your computer's IP:
```dart
static const String _serverIp = '192.168.0.105';  // Your computer IP
```

**✅ ALREADY DONE**: Configuration updated to `192.168.0.105`

---

## 🔨 Step 3: Build & Install App on Phone

### Check Connected Devices
```cmd
cd mobile
flutter devices
```

### Build and Install
```cmd
flutter run -d <DEVICE_ID>
```

**✅ CURRENTLY RUNNING**: Building and installing on device `59HYTWEYWOW8CAN7` (RMX3998)

---

## 🧪 Step 4: Test Complete KYC Flow

### 1. Register New User
- Open app on phone
- Click "Sign Up"
- Enter email and password
- Verify email OTP (check backend console for OTP)

### 2. Login
- Enter credentials
- Click "Login"

### 3. Complete KYC
- Navigate to KYC section
- Upload ID document (take photo or select from gallery)
- Wait for OCR processing
- **Check email inbox for OTP** (also logged in backend console)
- Enter OTP in app
- Should navigate to Feature Selection screen

### 4. Test SMS Parsing
- Grant SMS permissions when prompted
- Send test SMS from bank
- App should automatically detect and parse transaction

---

## 🔍 Troubleshooting

### Backend Issues

**Problem**: Backend not starting
```cmd
cd backend
npm install
node src/server.js
```

**Problem**: MongoDB connection error
- Ensure MongoDB is running: `mongod`
- Check connection string in `backend/.env`

**Problem**: Port 5001 already in use
```cmd
netstat -ano | findstr :5001
taskkill /PID <PID> /F
```

### Frontend Issues

**Problem**: Cannot connect to backend
- Verify computer IP: `ipconfig`
- Update `mobile/lib/config/constants.dart` with correct IP
- Ensure phone and computer on same WiFi
- Check backend is running: http://YOUR_IP:5001/api/health

**Problem**: Build errors
```cmd
cd mobile
flutter clean
flutter pub get
flutter run -d <DEVICE_ID>
```

**Problem**: App crashes on startup
- Check Flutter logs in terminal
- Verify all dependencies installed: `flutter pub get`
- Check Android permissions in `mobile/android/app/src/main/AndroidManifest.xml`

### KYC Issues

**Problem**: 401 Unauthorized errors
- Check token in API calls
- Verify user is logged in
- Check backend logs for authentication errors

**Problem**: File upload fails
- Check file size (max 50MB)
- Verify file type (JPEG, JPG, PNG, PDF)
- Check backend logs for multer errors

**Problem**: OTP not received
- **Check email inbox first** (may be in spam folder)
- Check backend console - OTP is also logged there
- Email sending enabled via tanna.at7@gmail.com
- Copy OTP from email or backend logs
- OTP expires in 10 minutes

**Problem**: White screen after OTP
- This has been fixed - should navigate to Feature Selection
- If still occurs, check Flutter logs for navigation errors

---

## 📝 Important Notes

### Backend Configuration
- **Port**: 5001
- **MongoDB**: localhost:27017/fbuddy
- **CORS**: Enabled for all origins (development only)
- **File Uploads**: Stored in `backend/uploads/`
- **OTP Delivery**: Email (tanna.at7@gmail.com) + Console logging
- **Email**: Professional branded template with 10-minute expiry

### Frontend Configuration
- **Emulator**: Uses `10.0.2.2:5001`
- **Physical Device**: Uses computer IP `192.168.0.105:5001`
- **Web**: Uses `localhost:5001`

### Security Notes
- JWT tokens expire in 30 days
- OTP expires in 10 minutes
- Email verification required for registration
- MFA required for KYC completion

---

## 🚀 Current Status

### ✅ Completed
- Backend running on port 5001
- Frontend configuration updated with computer IP (192.168.0.105)
- App building and installing on phone (RMX3998)
- All KYC endpoints working
- File upload fixed (accepts multiple MIME types)
- OTP verification working
- Navigation after KYC completion fixed

### 🔄 In Progress
- Installing app on physical device with correct IP configuration

### 📋 Next Steps
1. Wait for app installation to complete
2. Test complete KYC flow on physical device
3. Verify SMS parsing functionality
4. Test all features end-to-end

---

## 📞 Support

### Check Backend Logs
Backend console shows:
- All API requests
- Authentication status
- Generated OTPs
- OCR processing results
- Error messages

### Check Frontend Logs
Flutter console shows:
- API calls and responses
- Navigation events
- Error messages
- Debug logs

### Common Commands
```cmd
# Start backend
cd backend && node src/server.js

# Start frontend (emulator)
cd mobile && flutter run

# Start frontend (physical device)
cd mobile && flutter run -d <DEVICE_ID>

# Check connected devices
flutter devices

# Clean build
cd mobile && flutter clean && flutter pub get

# Check backend health
curl http://localhost:5001/api/health
```

---

## 🎉 Success Criteria

App is working correctly when:
- ✅ Backend responds to health check
- ✅ User can register and login
- ✅ KYC document upload succeeds
- ✅ OCR extracts data from document
- ✅ OTP is generated and verified
- ✅ App navigates to Feature Selection after KYC
- ✅ SMS permissions granted
- ✅ Bank SMS automatically parsed

---

**Last Updated**: January 16, 2026
**Backend Status**: Running on port 5001
**Frontend Status**: Installing on RMX3998 with IP 192.168.0.105
