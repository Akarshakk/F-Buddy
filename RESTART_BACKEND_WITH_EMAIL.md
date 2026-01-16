# 📧 Restart Backend with Email Configuration

## ✅ SMTP Configuration Added

I've updated your backend to send OTP emails via Gmail:

### Configuration Added to `.env`:
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_EMAIL=tanna.at7@gmail.com
SMTP_PASSWORD=erkhvdtibvadmxxc
```

---

## 🔄 Restart Backend to Apply Changes

### Step 1: Stop Current Backend
The backend is currently running (PID 13516). You need to stop it first.

**Option A: Find and close the terminal window running the backend**

**Option B: Kill the process manually**
```cmd
taskkill /PID 13516 /F
```

### Step 2: Start Backend Again
```cmd
cd backend
node src/server.js
```

Or use the batch file:
```cmd
start-backend.bat
```

---

## ✅ Verify Email is Working

After restarting, you should see in the backend console:

### Before (Email Not Configured):
```
[MFA] Email not configured. Use the OTP from console above.
```

### After (Email Configured):
```
[MFA] ✓ OTP email sent successfully to user@example.com
```

---

## 📧 How It Works Now

### 1. OTP Generation
When user requests OTP (during KYC or registration):
- OTP is generated (6 digits)
- **Logged to console** (for backup/debugging)
- **Sent via email** to user's email address

### 2. Email Content
Users will receive a professional email with:
- Subject: "Your Verification Code - F-Buddy"
- Large, centered OTP code
- 10-minute expiry notice
- Professional styling

### 3. Fallback
If email fails to send:
- Error is logged but doesn't break the flow
- OTP is still available in console
- User can still complete verification

---

## 🧪 Test Email Sending

### 1. Register New User
```
1. Open app on phone
2. Click "Sign Up"
3. Enter email: test@example.com
4. Enter password
5. Check BOTH:
   - Backend console (OTP logged)
   - Email inbox (OTP sent)
```

### 2. KYC Flow
```
1. Upload document
2. Request OTP
3. Check BOTH:
   - Backend console
   - Email inbox
```

---

## 🔍 Troubleshooting

### Email Not Sending?

**Check 1: Backend Console**
Look for:
```
[MFA] ✓ OTP email sent successfully to user@example.com
```

If you see:
```
[MFA] ⚠️ Email failed to send. Using console OTP instead.
[MFA] Email Error: <error message>
```

**Check 2: Gmail App Password**
- The password `erkhvdtibvadmxxc` should be a Gmail App Password
- Not your regular Gmail password
- Generate at: https://myaccount.google.com/apppasswords

**Check 3: Gmail Settings**
- 2-Step Verification must be enabled
- Less secure app access (if using regular password)

**Check 4: Backend Logs**
Look for SMTP connection errors:
```
[MFA] Failed to create email transporter: <error>
```

### Common Issues

**Issue**: "Invalid login" error
**Solution**: Use Gmail App Password, not regular password

**Issue**: "Connection timeout"
**Solution**: Check firewall, allow port 587

**Issue**: Email goes to spam
**Solution**: Normal for development, check spam folder

---

## 📝 Important Notes

### Development vs Production
- **Development**: OTP logged to console AND sent via email
- **Production**: Should only send via email (remove console logs)

### Security
- Gmail App Password is already configured
- Never commit `.env` file to git (already in `.gitignore`)
- OTP expires in 10 minutes
- OTP deleted after successful verification

### Email Delivery Time
- Usually instant (1-5 seconds)
- May take up to 30 seconds in some cases
- Always check spam folder if not received

---

## 🎯 Quick Commands

### Restart Backend
```cmd
# Stop current backend (close terminal or kill process)
taskkill /PID 13516 /F

# Start backend
cd backend
node src/server.js
```

### Test Email
```cmd
# In backend directory
node test-kyc-flow.js
```

### Check Backend Status
```cmd
curl http://192.168.0.105:5001/api/health
```

---

## ✅ Success Checklist

After restarting backend, verify:
- [ ] Backend starts without errors
- [ ] Console shows: `🚀 F Buddy Server running on port 5001`
- [ ] No SMTP error messages
- [ ] Register new user → Email received
- [ ] KYC OTP request → Email received
- [ ] OTP still logged to console (backup)

---

**Last Updated**: January 16, 2026
**SMTP Email**: tanna.at7@gmail.com
**Status**: ⚠️ Backend needs restart to apply changes
