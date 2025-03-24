import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CourseService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api';
  bool _isLoading = false;
  List<Map<String, dynamic>> _courses = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get courses => _courses;

  Future<List<Map<String, dynamic>>> getCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _courses = List<Map<String, dynamic>>.from(data);
        return _courses;
      } else {
        return [];
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCourseById(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courses/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}