import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api';
  bool _isLoading = false;
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _students = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get attendanceRecords => _attendanceRecords;
  List<Map<String, dynamic>> get students => _students;

  Future<List<Map<String, dynamic>>> getAttendanceRecords(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/attendance/course/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _attendanceRecords = List<Map<String, dynamic>>.from(data);
        return _attendanceRecords;
      } else {
        return [];
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsByCourse(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courses/$courseId/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _students = List<Map<String, dynamic>>.from(data);
        return _students;
      } else {
        return [];
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<bool> saveAttendance(String courseId, DateTime date, List<Map<String, dynamic>> attendanceData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/attendance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'courseId': courseId,
          'date': date.toIso8601String(),
          'attendanceData': attendanceData,
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
}