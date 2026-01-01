import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class BillScanResult {
  final String? rawText;
  final double? amount;
  final String? category;
  final String? date;
  final String? merchant;
  final double? confidence;

  BillScanResult({
    this.rawText,
    this.amount,
    this.category,
    this.date,
    this.merchant,
    this.confidence,
  });

  factory BillScanResult.fromJson(Map<String, dynamic> json) {
    return BillScanResult(
      rawText: json['rawText'],
      amount: json['amount']?.toDouble(),
      category: json['category'],
      date: json['date'],
      merchant: json['merchant'],
      confidence: json['confidence']?.toDouble(),
    );
  }
}

class BillScanService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> _getToken() async {
    return await _storage.read(key: StorageKeys.token);
  }

  /// Scan a bill image from bytes (works on both web and mobile)
  static Future<Map<String, dynamic>> scanBillFromBytes(Uint8List imageBytes) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }

      // Convert bytes to base64
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/bill/scan-base64'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': BillScanResult.fromJson(data['data']),
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to scan bill'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error scanning bill: ${e.toString()}'
      };
    }
  }

  /// Scan a bill from base64 encoded image
  static Future<Map<String, dynamic>> scanBillBase64(String base64Image) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/bill/scan-base64'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': BillScanResult.fromJson(data['data']),
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to scan bill'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error scanning bill: ${e.toString()}'
      };
    }
  }
}
