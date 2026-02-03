import 'package:flutter/material.dart';
import '../../services/kyc_service.dart';
import '../../config/app_theme.dart';

class MfaScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final bool isActive; // Only request OTP when this screen is active

  const MfaScreen({super.key, required this.onSuccess, this.isActive = false});

  @override
  _MfaScreenState createState() => _MfaScreenState();
}

class _MfaScreenState extends State<MfaScreen> {
  final KycService _kycService = KycService();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isVerifying = false;
  bool _otpRequested = false; // Track if we already requested OTP

  @override
  void initState() {
    super.initState();
    // Only request OTP if screen is active on init
    if (widget.isActive && !_otpRequested) {
      _requestOtp();
    }
  }

  @override
  void didUpdateWidget(MfaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Request OTP when screen becomes active (and we haven't already)
    if (widget.isActive && !oldWidget.isActive && !_otpRequested) {
      _requestOtp();
    }
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
      _otpRequested = true; // Mark that we've requested OTP
    });
    try {
      await _kycService.requestMfa();
      setState(() {
         _otpSent = true;
         _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ OTP sent to your email. Check backend console for OTP code!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          )
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 6-digit OTP'),
          backgroundColor: Colors.orange,
        )
      );
      return;
    }

    setState(() => _isVerifying = true);
    try {
      print('[MFA Screen] Verifying OTP: ${_otpController.text}');
      await _kycService.verifyMfa(_otpController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Verification Complete! Welcome to Finzo!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          )
        );
        
        // Wait a moment for user to see success message
        await Future.delayed(const Duration(seconds: 1));
        
        // Call success callback
        widget.onSuccess();
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please check and try again.'),
            backgroundColor: Colors.red,
          )
        );
      }
      print('[MFA Screen] Verification failed: $e');
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read, size: 80, color: FinzoTheme.brandPrimary(context)),
          const SizedBox(height: 20),
          Text(
            'Secure your Account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FinzoTheme.textPrimary(context)),
          ),
          const SizedBox(height: 10),
          Text(
            'We sent a 6-digit code to your email. Please enter it below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FinzoTheme.textSecondary(context)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FinzoTheme.brandPrimary(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: FinzoTheme.brandPrimary(context), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Check backend console for OTP code',
                    style: TextStyle(color: FinzoTheme.brandPrimary(context), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold, color: FinzoTheme.textPrimary(context)),
            decoration: InputDecoration(
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: FinzoTheme.brandPrimary(context), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: FinzoTheme.brandPrimary(context), width: 2),
              ),
              hintText: '3 0 1 4 7 2',
              hintStyle: TextStyle(color: FinzoTheme.textTertiary(context)),
              filled: true,
              fillColor: FinzoTheme.surface(context),
            ),
            onChanged: (value) {
              // Auto-verify when 6 digits entered
              if (value.length == 6 && _otpSent && !_isVerifying) {
                _verifyOtp();
              }
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_otpSent && !_isVerifying && _otpController.text.length == 6) ? _verifyOtp : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: FinzoTheme.brandPrimary(context),
                disabledBackgroundColor: FinzoTheme.divider(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isVerifying 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Verifying...', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ],
                  )
                : const Text('Verify & Finish', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
             onPressed: (_isLoading || _isVerifying) ? null : _requestOtp,
             child: Text(
               'Resend Code',
               style: TextStyle(
                 color: (_isLoading || _isVerifying) ? FinzoTheme.textTertiary(context) : FinzoTheme.brandPrimary(context),
                 fontWeight: FontWeight.w600,
               ),
             ),
          )
        ],
      ),
    );
  }
}
