import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GradesService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api';
  List<dynamic> _grades = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<dynamic> get grades => _grades;

  Future<Map<String, dynamic>> getStudentGrades(String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/grades/student/$studentId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> decodedResp = json.decode(response.body);
      if (response.statusCode == 200) {
        _grades = decodedResp['grades'] ?? [];
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': response.statusCode == 200,
        'message': decodedResp['message'] ?? 'Error al obtener las calificaciones',
        'grades': _grades,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Error de conexión',
      };
    }
  }

  Future<Map<String, dynamic>> updateGrade(String gradeId, Map<String, dynamic> gradeData) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/grades/$gradeId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(gradeData),
      );

      final Map<String, dynamic> decodedResp = json.decode(response.body);
      if (response.statusCode == 200) {
        // Actualizar la calificación en la lista local
        final index = _grades.indexWhere((grade) => grade['_id'] == gradeId);
        if (index != -1) {
          _grades[index] = decodedResp['grade'];
          notifyListeners();
        }
      }

      return {
        'success': response.statusCode == 200,
        'message': decodedResp['message'] ?? 'Error al actualizar la calificación',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión',
      };
    }
  }

  Future<Map<String, dynamic>> getCourseGrades(String courseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/grades/course/$courseId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> decodedResp = json.decode(response.body);
      if (response.statusCode == 200) {
        _grades = decodedResp['grades'] ?? [];
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': response.statusCode == 200,
        'message': decodedResp['message'] ?? 'Error al obtener las calificaciones del curso',
        'grades': _grades,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Error de conexión',
      };
    }
  }
}