import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/kyc_service.dart';

class SelfieScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const SelfieScreen({Key? key, required this.onSuccess}) : super(key: key);

  @override
  _SelfieScreenState createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen> {
  final KycService _kycService = KycService();
  XFile? _image;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera, 
      preferredCameraDevice: CameraDevice.front
    );

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<void> _uploadSelfie() async {
    if (_image == null) return;

    setState(() => _isUploading = true);

    try {
      final result = await _kycService.uploadSelfie(_image!);
      
      // Check if face verification was successful
      if (result['success'] == true) {
        // Face matched successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face verified successfully! ✓'),
            backgroundColor: Colors.green,
          )
        );
        widget.onSuccess();
      } else {
        // Face verification failed
        final matchScore = result['data']?['matchScore'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Face verification failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          )
        );
        
        // Show detailed error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Verification Failed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The face in your selfie does not match the document photo.'),
                SizedBox(height: 12),
                Text('Match Score: ${matchScore.toStringAsFixed(1)}% (Required: 80%)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 12),
                Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Ensure good lighting'),
                Text('• Remove glasses or caps'),
                Text('• Face the camera directly'),
                Text('• Use the same person\'s photo'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Try Again'),
              ),
            ],
          ),
        );
        
        // Clear the image so user can retake
        setState(() {
          _image = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Take a Selfie',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Ensure your face is clearly visible and well-lit. Avoid glasses or caps.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 30),
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[200],
              backgroundImage: _image != null 
                 ? (kIsWeb 
                     ? NetworkImage(_image!.path) 
                     : FileImage(File(_image!.path)) as ImageProvider)
                 : null,
              child: _image == null
                  ? Icon(Icons.camera_front, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: (_image != null && !_isUploading) ? _uploadSelfie : null,
            style: ElevatedButton.styleFrom(
               padding: EdgeInsets.symmetric(vertical: 15),
               backgroundColor: Colors.blue,
            ),
            child: _isUploading
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Verify Face', style: TextStyle(fontSize: 16)),
          ),
           if (_image == null)
            TextButton(
              onPressed: _pickImage,
              child: Text('Open Camera'),
            ),
        ],
      ),
    );
  }
}
