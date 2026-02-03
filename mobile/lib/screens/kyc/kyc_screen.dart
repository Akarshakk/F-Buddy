import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/kyc_service.dart';
import '../../config/app_theme.dart';
import 'document_upload_screen.dart';
import 'selfie_screen.dart';
import 'mfa_screen.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  _KycScreenState createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final KycService _kycService = KycService();
  int _currentStep = 0;
  bool _isLoading = true;
  String _status = 'NOT_STARTED';

  @override
  void initState() {
    super.initState();
    _fetchKycStatus();
  }

  Future<void> _fetchKycStatus() async {
    try {
      final data = await _kycService.getKycStatus();
      if (!mounted) return; // Check if widget is still mounted
      
      setState(() {
        _currentStep = data['step'] ?? 0;
        _status = data['status'] ?? 'NOT_STARTED';
        _isLoading = false;
      });
      
      if (_status == 'VERIFIED') {
        // Already verified, navigate to feature selection
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
      }
    } catch (e) {
      print('[KYC] Exception: $e');
      if (!mounted) return; // Check if widget is still mounted
      
      // Even if API fails, show the screen (start from step 0)
      setState(() {
        _currentStep = 0;
        _status = 'NOT_STARTED';
        _isLoading = false;
      });
      
      // Show error message but don't block the UI
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not load KYC status. Starting fresh.'),
                duration: Duration(seconds: 2),
              )
            );
          }
        });
      }
    }
  }

  void _nextStep() {
    if (mounted) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _completeKyc() {
    if (mounted) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 16),
                Text('Verification Complete!', textAlign: TextAlign.center),
              ],
            ),
            content: const Text(
              'Your account has been successfully verified. Welcome to Finzo!',
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close dialog
                    // Navigate to feature selection screen
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Get Started', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Setup'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Skip KYC and go to feature selection
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: Text(
              'Skip',
              style: TextStyle(
                color: FinzoTheme.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressStepper(),
          Expanded(
            child: IndexedStack(
              index: _currentStep.clamp(0, 3) > 3 ? 3 : _currentStep.clamp(0, 3), 
              children: [
                 // Step 0: Document Upload
                 DocumentUploadScreen(onSuccess: _nextStep),
                 // Step 1: Selfie
                 SelfieScreen(onSuccess: _nextStep),
                 // Step 2: MFA/OTP Verification
                 MfaScreen(onSuccess: _completeKyc, isActive: _currentStep == 2),
                 // Step 3: Completed (shouldn't normally reach here)
                 Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.check_circle, color: Colors.green, size: 100),
                       const SizedBox(height: 20),
                       const Text(
                         'Verification Complete!',
                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: 40),
                       ElevatedButton(
                         onPressed: () {
                           Navigator.of(context).pushReplacementNamed('/home');
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.blue,
                           padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                           ),
                         ),
                         child: const Text(
                           'Go to Home',
                           style: TextStyle(color: Colors.white, fontSize: 16),
                         ),
                       ),
                     ],
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      color: FinzoTheme.surface(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepIcon(0, Icons.upload_file, 'Docs'),
          _buildLine(0),
          _buildStepIcon(1, Icons.camera_alt, 'Selfie'),
          _buildLine(1),
          _buildStepIcon(2, Icons.security, 'Secure'),
          _buildLine(2),
          _buildStepIcon(3, Icons.check_circle, 'Done'),
        ],
      ),
    );
  }

  Widget _buildStepIcon(int stepIndex, IconData icon, String label) {
    bool isActive = _currentStep >= stepIndex;
    bool isCompleted = _currentStep > stepIndex;

    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive ? FinzoTheme.brandPrimary(context) : FinzoTheme.divider(context),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? FinzoTheme.brandPrimary(context) : FinzoTheme.textSecondary(context),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(int stepIndex) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > stepIndex ? FinzoTheme.brandPrimary(context) : FinzoTheme.divider(context),
      ),
    );
  }
}
