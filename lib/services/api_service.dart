// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 서버 연결시 (미완성) 
  static const String _baseUrl = 'http://192.168.xxx.xxx:8000';

  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);
      return token;
    } else {
      throw Exception('Failed to login: ${json.decode(response.body)['detail']}');
    }
  }
  
  Future<http.Response> getWithAuth(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    return await http.get(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('API Error: ${json.decode(response.body)['detail']}');
    }
  }
}