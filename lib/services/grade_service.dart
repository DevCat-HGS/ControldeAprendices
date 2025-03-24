import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GradeService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api';
  bool _isLoading = false;
  List<Map<String, dynamic>> _grades = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get grades => _grades;

  Future<List<Map<String, dynamic>>> getStudentGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    if (token == null || userId == null) {
      return [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/evaluations/student/$userId/grades'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _grades = List<Map<String, dynamic>>.from(data);
        return _grades;
      } else {
        return [];
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<bool> submitGrade(String evaluationId, String studentId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/evaluations/$evaluationId/grade'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'studentId': studentId,
          'score': score,
        }),
      );

      _isLoading = false;
      notifyListeners();

      return response.statusCode == 201;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getEvaluationGrades(String evaluationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/evaluations/$evaluationId/grades'),
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