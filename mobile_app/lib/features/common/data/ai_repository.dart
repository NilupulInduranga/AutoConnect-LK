import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiRepositoryProvider = Provider((ref) => AiRepository());

class AiRepository {
  // 10.0.2.2 is the localhost alias for Android Emulator
  // For iOS Simulator use 127.0.0.1
  // For physical device, use your machine's local IP (e.g. 192.168.1.x)
  static const String baseUrl = 'http://10.0.2.2:8000'; 

  Future<Map<String, dynamic>> analyzeListing(Map<String, dynamic> listingData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze_listing'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(listingData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze listing: ${response.statusCode}');
      }
    } catch (e) {
      // If AI service is down, just return approved (fail open) or throw
      // For MVP, let's log and return a default "safe" response so app doesn't crash
      print('AI Service Error: $e');
      return {'status': 'approved', 'risk_score': 0.0}; 
    }
  }

  Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze_image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': imageUrl}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      print('AI Service Error (Image): $e');
      return {}; 
    }
  }
}
