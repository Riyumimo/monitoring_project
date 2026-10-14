import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to login: ${response.body}');
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<List<dynamic>> getProjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch projects');
    } catch (e) {
      throw Exception('Error fetching projects: $e');
    }
  }

  Future<Map<String, dynamic>> createProject(Map<String, dynamic> project) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(project),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to create project');
    } catch (e) {
      throw Exception('Error creating project: $e');
    }
  }

  Future<void> updateProject(String id, Map<String, dynamic> project) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/projects/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(project),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update project');
      }
    } catch (e) {
      throw Exception('Error updating project: $e');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/projects/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete project');
      }
    } catch (e) {
      throw Exception('Error deleting project: $e');
    }
  }
}
