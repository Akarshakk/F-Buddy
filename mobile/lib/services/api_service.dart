import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Get auth token
  static Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.token);
  }
  
  // Save auth token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.token, value: token);
  }
  
  // Delete auth token
  static Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.token);
  }
  
  // Get headers
  static Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // GET request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      print('[API] GET ${uri.toString()}'); // Debug log
      
      final response = await http.get(
        uri,
        headers: await _getHeaders(requiresAuth: requiresAuth),
      );
      
      print('[API] Response: ${response.statusCode}'); // Debug log
      return _handleResponse(response);
    } catch (e) {
      print('[API] Error: $e'); // Debug log
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
  
  // POST request
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      print('[API] POST $url'); // Debug log
      
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(requiresAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      
      print('[API] Response: ${response.statusCode}'); // Debug log
      return _handleResponse(response);
    } catch (e) {
      print('[API] Error: $e'); // Debug log
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
  
  // PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: await _getHeaders(requiresAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
  
  // DELETE request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: await _getHeaders(requiresAuth: requiresAuth),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
  
  // Handle response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse response',
        'statusCode': response.statusCode,
      };
    }
  }

  // Upload file (multipart)
  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file, {
    String fieldName = 'file',
    bool requiresAuth = true,
  }) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      print('[API] UPLOAD $url');

      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add auth header
      if (requiresAuth) {
        final token = await getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        fieldName,
        file.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('[API] Upload Response: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('[API] Upload Error: $e');
      return {'success': false, 'message': 'Upload error: ${e.toString()}'};
    }
  }
}
