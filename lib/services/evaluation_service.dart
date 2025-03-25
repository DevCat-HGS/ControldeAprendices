import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EvaluationService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api';
  bool _isLoading = false;
  List<Map<String, dynamic>> _evaluations = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get evaluations => _evaluations;

  Future<List<Map<String, dynamic>>> getEvaluations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userRole = prefs.getString('userRole');
    final userId = prefs.getString('userId');

    if (token == null) {
      return [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = userRole == 'instructor'
          ? Uri.parse('$_baseUrl/evaluations')
          : Uri.parse('$_baseUrl/evaluations/student/$userId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _evaluations = List<Map<String, dynamic>>.from(data);
        return _evaluations;
      } else {
        return [];
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<bool> createEvaluation(Map<String, dynamic> evaluationData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/evaluations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(evaluationData),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        await getEvaluations(); // Refresh the list
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCourseEvaluations(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/evaluations/course/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        return [];
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentEvaluations(String courseId, String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/evaluations/course/$courseId/student/$studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        return [];
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }
}