import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> 
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (_otpController.text.length != 6) {
      _showSnackBar('Please enter the 6-digit OTP', isError: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        ApiConstants.verifyEmail,
        body: {
          'email': widget.email,
          'otp': _otpController.text,
        },
        requiresAuth: false,
      );

      if (response['success'] == true && response['data'] != null) {
        final token = response['data']['token'];
        if (token != null) {
          await ApiService.saveToken(token);
        }
        
        if (mounted) {
          _showSnackBar('Account created successfully! 🎉', isSuccess: true);
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        if (mounted) {
          _showSnackBar(response['message'] ?? 'Invalid OTP', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    try {
      final response = await ApiService.post(
        ApiConstants.resendOtp,
        body: {'email': widget.email},
        requiresAuth: false,
      );

      if (mounted) {
        _showSnackBar(
          response['message'] ?? 'OTP sent!',
          isSuccess: response['success'] == true,
          isError: response['success'] != true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: FinzoTypography.bodyMedium(color: Colors.white)),
        backgroundColor: isSuccess 
            ? FinzoColors.success 
            : isError 
                ? FinzoColors.error 
                : FinzoColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FinzoRadius.sm)),
        margin: const EdgeInsets.all(FinzoSpacing.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      appBar: AppBar(
        title: Text(
          'Verify Email',
          style: FinzoTypography.titleMedium(color: FinzoTheme.textPrimary(context)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(FinzoSpacing.xs),
            decoration: BoxDecoration(
              color: FinzoTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(FinzoRadius.sm),
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: FinzoTheme.textPrimary(context),
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FinzoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FinzoSpacing.xxl),
              // Animated Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FinzoColors.brandPrimary.withOpacity(0.1),
                        FinzoColors.brandSecondary.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    size: 50,
                    color: FinzoTheme.brandAccent(context),
                  ),
                ),
              ),
              const SizedBox(height: FinzoSpacing.xl),
              Text(
                'Verify Your Email',
                style: FinzoTypography.displaySmall(
                  color: FinzoTheme.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FinzoSpacing.sm),
              Text(
                'We sent a 6-digit verification code to',
                style: FinzoTypography.bodyLarge(
                  color: FinzoTheme.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FinzoSpacing.xs),
              Text(
                widget.email,
                style: FinzoTypography.titleMedium(
                  color: FinzoTheme.textPrimary(context),
                ).copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FinzoSpacing.xl),
              
              // OTP Input
              Container(
                decoration: BoxDecoration(
                  color: FinzoTheme.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(FinzoRadius.lg),
                  border: Border.all(color: FinzoTheme.divider(context)),
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: FinzoTypography.displaySmall(
                    color: FinzoTheme.textPrimary(context),
                  ).copyWith(letterSpacing: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: FinzoTypography.displaySmall(
                      color: FinzoTheme.textSecondary(context).withOpacity(0.3),
                    ).copyWith(letterSpacing: 16),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: FinzoSpacing.lg,
                      vertical: FinzoSpacing.lg,
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length == 6) {
                      _verifyEmail();
                    }
                  },
                ),
              ),
              const SizedBox(height: FinzoSpacing.xl),
              
              // Verify Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [FinzoColors.brandPrimary, FinzoColors.brandSecondary],
                  ),
                  borderRadius: BorderRadius.circular(FinzoRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: FinzoColors.brandPrimary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FinzoRadius.md),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Verify Email',
                          style: FinzoTypography.labelLarge(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: FinzoSpacing.md),
              
              // Resend Button
              TextButton(
                onPressed: _isResending ? null : _resendOtp,
                child: Text(
                  _isResending ? 'Sending...' : 'Resend Code',
                  style: FinzoTypography.labelMedium(
                    color: FinzoTheme.brandAccent(context),
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: FinzoSpacing.lg),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(FinzoSpacing.md),
                decoration: BoxDecoration(
                  color: FinzoColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FinzoRadius.md),
                  border: Border.all(color: FinzoColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: FinzoColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: FinzoSpacing.sm),
                    Expanded(
                      child: Text(
                        'Check your email inbox and spam folder for the OTP',
                        style: FinzoTypography.bodySmall(color: FinzoColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


