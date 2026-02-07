import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        ApiConstants.register,
        body: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'monthlyBudget': double.tryParse(_budgetController.text) ?? 0,
        },
        requiresAuth: false,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        _showErrorSnackBar(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: FinzoTypography.bodyMedium(color: Colors.white)),
        backgroundColor: FinzoColors.error,
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(FinzoSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Create Account',
                    style: FinzoTypography.displaySmall(
                      color: FinzoTheme.textPrimary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: FinzoSpacing.sm),
                  Text(
                    'Join thousands managing their finances',
                    style: FinzoTypography.bodyLarge(
                      color: FinzoTheme.textSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: FinzoSpacing.xl),
                  
                  // Name field
                  _buildTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    hint: 'Your full name',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: FinzoSpacing.md),
                  
                  // Email field
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'your@email.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: FinzoSpacing.md),
                  
                  // Password field
                  _buildTextField(
                    label: 'Password',
                    controller: _passwordController,
                    hint: 'Min. 6 characters',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: FinzoTheme.textSecondary(context),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: FinzoSpacing.md),
                  
                  // Confirm Password field
                  _buildTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    hint: 'Confirm password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: FinzoTheme.textSecondary(context),
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: FinzoSpacing.md),
                  
                  // Monthly Budget field
                  _buildTextField(
                    label: 'Monthly Budget',
                    controller: _budgetController,
                    hint: 'Enter your monthly budget',
                    icon: Icons.account_balance_wallet_outlined,
                    keyboardType: TextInputType.number,
                    prefixText: '₹ ',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid amount';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: FinzoSpacing.xs),
                  Text(
                    'Optional - you can update later',
                    style: FinzoTypography.bodySmall(
                      color: FinzoTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: FinzoSpacing.xl),
                  
                  // Register button
                  _buildPrimaryButton(
                    label: 'Create Account',
                    onPressed: _isLoading ? null : _register,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: FinzoSpacing.lg),
                  
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: FinzoTypography.bodyMedium(
                          color: FinzoTheme.textSecondary(context),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sign In',
                          style: FinzoTypography.labelLarge(
                            color: FinzoTheme.brandAccent(context),
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FinzoSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FinzoTypography.labelMedium(
            color: FinzoTheme.textPrimary(context),
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: FinzoSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          style: FinzoTypography.bodyMedium(color: FinzoTheme.textPrimary(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: FinzoTypography.bodyMedium(color: FinzoTheme.textSecondary(context)),
            prefixIcon: Icon(icon, size: 20, color: FinzoTheme.textSecondary(context)),
            prefixText: prefixText,
            prefixStyle: FinzoTypography.bodyMedium(color: FinzoTheme.textPrimary(context)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: FinzoTheme.surfaceVariant(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FinzoRadius.md),
              borderSide: BorderSide(color: FinzoTheme.divider(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FinzoRadius.md),
              borderSide: BorderSide(color: FinzoTheme.divider(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FinzoRadius.md),
              borderSide: BorderSide(color: FinzoTheme.brandAccent(context), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FinzoRadius.md),
              borderSide: const BorderSide(color: FinzoColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: FinzoSpacing.md,
              vertical: FinzoSpacing.md,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
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
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FinzoRadius.md),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label, style: FinzoTypography.labelLarge(color: Colors.white)),
      ),
    );
  }
}