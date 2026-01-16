# F-Buddy Testing Checklist

## ✅ Current Status
- **Backend**: Running on port 5001 (Computer IP: 192.168.0.105)
- **Frontend**: Installed and running on RMX3998 (Android phone)
- **Configuration**: Updated to use computer IP instead of emulator IP

---

## 🧪 Test Flow

### 1. Registration & Login ✓
```
1. Open app on phone
2. Click "Sign Up"
3. Enter email: test@example.com
4. Enter password: Test123!
5. Check backend console for OTP
6. Enter OTP to verify email
7. Login with credentials
```

### 2. KYC Flow ✓
```
1. Navigate to KYC section
2. Click "Upload Document"
3. Take photo or select from gallery
4. Wait for upload (check backend logs)
5. OCR will extract data automatically
6. Check backend console for OTP
7. Enter OTP in app
8. Should navigate to Feature Selection screen
```

### 3. SMS Parsing
```
1. Grant SMS permissions when prompted
2. Send test SMS from bank number
3. App should auto-detect and parse
4. Check expense list for new entry
```

---

## 🔍 What to Check

### Backend Console Should Show:
```
✅ API requests from phone (not 10.0.2.2)
✅ Authentication successful
✅ File upload successful
✅ OCR processing results
✅ Generated OTP (copy this!)
✅ OTP verification success
```

### Phone App Should:
```
✅ Connect to backend (no connection errors)
✅ Upload documents successfully
✅ Show OCR extracted data
✅ Accept OTP and verify
✅ Navigate to Feature Selection after KYC
✅ Request SMS permissions
✅ Parse bank SMS automatically
```

---

## 🐛 Quick Fixes

### If app can't connect to backend:
1. Check backend is running: http://192.168.0.105:5001/api/health
2. Verify phone and computer on same WiFi
3. Check Windows Firewall (allow port 5001)

### If OTP not working:
1. Check backend console for generated OTP
2. Copy exact OTP (6 digits)
3. OTP expires in 10 minutes

### If file upload fails:
1. Check file size (max 50MB)
2. Try different image format
3. Check backend logs for error

---

## 📝 Backend Commands

### Check if backend is running:
```cmd
netstat -ano | findstr :5001
```

### Start backend:
```cmd
cd backend
node src/server.js
```

### Test backend health:
```cmd
curl http://192.168.0.105:5001/api/health
```

---

## 📱 Flutter Commands

### Hot reload (after code changes):
Press `r` in Flutter terminal

### Hot restart:
Press `R` in Flutter terminal

### Quit app:
Press `q` in Flutter terminal

### Rebuild and reinstall:
```cmd
cd mobile
flutter run -d 59HYTWEYWOW8CAN7
```

---

## 🎯 Success Indicators

### ✅ Everything Working When:
1. Backend shows requests from 192.168.0.105 (not 10.0.2.2)
2. User can register and login
3. KYC document uploads successfully
4. OCR extracts data from document
5. OTP verification works
6. App navigates to Feature Selection
7. SMS permissions granted
8. Bank SMS parsed automatically

---

## 📞 Need Help?

### Check Backend Logs
Look for:
- `[AuthMiddleware] User authenticated`
- `[OCR] Processing document`
- `[MFA] GENERATED OTP FOR`
- `POST /api/kyc/upload-document 200`

### Check Flutter Logs
Look for:
- `[API] POST http://192.168.0.105:5001/api/...`
- `[KYC] Upload successful`
- `[KYC] OCR data received`
- Navigation events

---

**Last Updated**: January 16, 2026
**App Version**: Running on RMX3998
**Backend**: 192.168.0.105:5001
