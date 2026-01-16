import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';

class KycService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get baseUrl {
    // Use the centralized API configuration from constants.dart
    return '${ApiConstants.baseUrl}/kyc';
  }

  Future<String?> _getToken() async {
     return await _storage.read(key: StorageKeys.token);
  }

  Future<Map<String, dynamic>> getKycStatus() async {
    try {
      final token = await _getToken();
      print('[KYC] Getting status with token: ${token?.substring(0, 20)}...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[KYC] Status response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[KYC] Status data: $data');
        return data['data'];
      } else {
        final error = json.decode(response.body);
        print('[KYC] Status error: $error');
        throw Exception(error['message'] ?? 'Failed to load KYC status');
      }
    } catch (e) {
      print('[KYC] Exception: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadDocument(XFile file, String type) async {
    try {
      final token = await _getToken();
      print('[KYC] Uploading document type: $type');
      print('[KYC] File name: ${file.name}');
      print('[KYC] File path: ${file.path}');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-document'));
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['documentType'] = type;
      
      // Cross-platform file reading
      final bytes = await file.readAsBytes();
      
      // Determine mimetype from file extension
      String mimeType = 'image/jpeg';
      final extension = file.name.toLowerCase().split('.').last;
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'pdf') {
        mimeType = 'application/pdf';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      }
      
      print('[KYC] Using mimetype: $mimeType');
      
      // Ensure filename has proper extension
      String filename = file.name;
      if (!filename.contains('.')) {
        filename = 'document.$extension';
      }
      
      request.files.add(http.MultipartFile.fromBytes(
        'document', 
        bytes, 
        filename: filename,
        contentType: http.MediaType.parse(mimeType)
      ));

      print('[KYC] Sending document upload request...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('[KYC] Upload response: ${response.statusCode}');
      print('[KYC] Upload response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[KYC] Upload success: $data');
        return data;
      } else {
        final error = json.decode(response.body);
        print('[KYC] Upload error: $error');
        throw Exception(error['message'] ?? 'Upload failed');
      }
    } catch (e) {
      print('[KYC] Upload exception: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadSelfie(XFile file) async {
    try {
      final token = await _getToken();
      print('[KYC] Uploading selfie...');
      print('[KYC] File name: ${file.name}');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-selfie'));
      
      request.headers['Authorization'] = 'Bearer $token';
      
      final bytes = await file.readAsBytes();
      
      // Determine mimetype from file extension
      String mimeType = 'image/jpeg';
      final extension = file.name.toLowerCase().split('.').last;
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      }
      
      print('[KYC] Using mimetype: $mimeType');
      
      // Ensure filename has proper extension
      String filename = file.name;
      if (!filename.contains('.')) {
        filename = 'selfie.$extension';
      }
      
      request.files.add(http.MultipartFile.fromBytes(
        'selfie', 
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType)
      ));

      print('[KYC] Sending selfie upload request...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('[KYC] Selfie upload response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[KYC] Selfie upload success: $data');
        return data;
      } else {
        final error = json.decode(response.body);
        print('[KYC] Selfie upload error: $error');
        throw Exception(error['message'] ?? 'Selfie upload failed');
      }
    } catch (e) {
      print('[KYC] Selfie upload exception: $e');
      rethrow;
    }
  }

  Future<void> requestMfa() async {
    try {
      final token = await _getToken();
      print('[KYC] Requesting MFA/OTP...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/mfa/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[KYC] MFA request response: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        print('[KYC] MFA request error: $error');
        throw Exception(error['message'] ?? 'Failed to request OTP');
      }
      
      print('[KYC] OTP sent successfully');
    } catch (e) {
      print('[KYC] MFA request exception: $e');
      rethrow;
    }
  }

  Future<void> verifyMfa(String otp) async {
    try {
      final token = await _getToken();
      print('[KYC] Verifying OTP: $otp');
      
      final response = await http.post(
        Uri.parse('$baseUrl/mfa/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'otp': otp}),
      );

      print('[KYC] MFA verify response: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        print('[KYC] MFA verify error: $error');
        throw Exception(error['message'] ?? 'Invalid OTP');
      }
      
      print('[KYC] OTP verified successfully');
    } catch (e) {
      print('[KYC] MFA verify exception: $e');
      rethrow;
    }
  }
}
