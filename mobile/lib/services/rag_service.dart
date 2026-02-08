import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class RagService {
  // RAG Service runs on a separate port
  static String get baseUrl {
    // Use same IP as main API but different port
    final mainUrl = ApiConstants.baseUrl;
    final serverIp = mainUrl.split('://')[1].split(':')[0];
    return 'http://$serverIp:5002';
  }

  /// Send a chat query to the RAG service with optional context
  Future<RagResponse> chat(String query, {Map<String, dynamic>? context}) async {
    try {
      print('[RAG] Sending query to $baseUrl/chat: $query');
      final body = {
        'query': query,
        if (context != null) 'context': context,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('[RAG] Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RagResponse.fromJson(data);
      } else {
        return RagResponse(
          success: false,
          answer: '',
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[RAG] Error: $e');
      return RagResponse(
        success: false,
        answer: '',
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Check if RAG service is available
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get statistics about the RAG knowledge base
  Future<RagStats?> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return RagStats.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class RagResponse {
  final bool success;
  final String answer;
  final List<String> sources;
  final int? contextUsed;
  final String? message;

  RagResponse({
    required this.success,
    required this.answer,
    this.sources = const [],
    this.contextUsed,
    this.message,
  });

  factory RagResponse.fromJson(Map<String, dynamic> json) {
    return RagResponse(
      success: json['success'] ?? false,
      answer: json['answer'] ?? '',
      sources: json['sources'] != null
          ? List<String>.from(json['sources'])
          : [],
      contextUsed: json['context_used'],
      message: json['message'],
    );
  }
}

class RagStats {
  final int totalVectors;
  final int dimension;
  final String indexName;

  RagStats({
    required this.totalVectors,
    required this.dimension,
    required this.indexName,
  });

  factory RagStats.fromJson(Map<String, dynamic> json) {
    return RagStats(
      totalVectors: json['total_vectors'] ?? 0,
      dimension: json['dimension'] ?? 384,
      indexName: json['index_name'] ?? '',
    );
  }
}


