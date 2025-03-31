import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CourseService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api';
  bool _isLoading = false;
  List<dynamic> _courses = [];

  bool get isLoading => _isLoading;
  List<dynamic> get courses => _courses;

  // Obtener el token almacenado
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Obtener todos los cursos
  Future<bool> getCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/courses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _courses = data['data'];
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener un curso específico
  Future<Map<String, dynamic>?> getCourse(String courseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/courses/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Crear un nuevo curso (solo para instructores)
  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> courseData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'No se encontró el token de autenticación'};
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/courses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(courseData),
      );

      _isLoading = false;
      notifyListeners();

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        await getCourses(); // Actualizar la lista de cursos
        return {'success': true, 'message': 'Curso creado exitosamente'};
      }
      return {'success': false, 'message': data['message'] ?? 'Error al crear el curso'};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error inesperado al crear el curso'};
    }
  }

  // Actualizar un curso existente (solo para instructores)
  Future<Map<String, dynamic>> updateCourse(String courseId, Map<String, dynamic> courseData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'No se encontró el token de autenticación'};
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/courses/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(courseData),
      );

      _isLoading = false;
      notifyListeners();

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await getCourses(); // Actualizar la lista de cursos
        return {'success': true, 'message': 'Curso actualizado exitosamente'};
      }
      return {'success': false, 'message': data['message'] ?? 'Error al actualizar el curso'};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error inesperado al actualizar el curso'};
    }
  }

  // Eliminar un curso (solo para instructores)
  Future<Map<String, dynamic>> deleteCourse(String courseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'No se encontró el token de autenticación'};
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/courses/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      _isLoading = false;
      notifyListeners();

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await getCourses(); // Actualizar la lista de cursos
        return {'success': true, 'message': 'Curso eliminado exitosamente'};
      }
      return {'success': false, 'message': data['message'] ?? 'Error al eliminar el curso'};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error inesperado al eliminar el curso'};
    }
  }

  // Agregar un estudiante a un curso (solo para instructores)
  Future<bool> addStudentToCourse(String courseId, String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/courses/$courseId/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode({'studentId': studentId}),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        await getCourses(); // Actualizar la lista de cursos
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar un estudiante de un curso (solo para instructores)
  Future<bool> removeStudentFromCourse(String courseId, String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/courses/$courseId/students/$studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        await getCourses(); // Actualizar la lista de cursos
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}