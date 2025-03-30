import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api';
  bool _isLoading = false;
  List<dynamic> _attendances = [];

  bool get isLoading => _isLoading;
  List<dynamic> get attendances => _attendances;

  // Obtener el token almacenado
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Obtener todas las asistencias
  Future<bool> getAttendances() async {
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
        Uri.parse('$_baseUrl/attendance'),
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
          _attendances = data['data'];
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

  // Obtener asistencias por curso
  Future<List<dynamic>?> getAttendancesByCourse(String courseId) async {
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
        Uri.parse('$_baseUrl/attendance/course/$courseId'),
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

  // Obtener una asistencia específica
  Future<Map<String, dynamic>?> getAttendance(String attendanceId) async {
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
        Uri.parse('$_baseUrl/attendance/$attendanceId'),
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

  // Crear un nuevo registro de asistencia (solo para instructores)
  Future<bool> createAttendance(Map<String, dynamic> attendanceData) async {
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
        Uri.parse('$_baseUrl/attendance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(attendanceData),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        await getAttendances(); // Actualizar la lista de asistencias
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar un registro de asistencia existente (solo para instructores)
  Future<bool> updateAttendance(String attendanceId, Map<String, dynamic> attendanceData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/attendance/$attendanceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(attendanceData),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        await getAttendances(); // Actualizar la lista de asistencias
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar un registro de asistencia (solo para instructores)
  Future<bool> deleteAttendance(String attendanceId) async {
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
        Uri.parse('$_baseUrl/attendance/$attendanceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        await getAttendances(); // Actualizar la lista de asistencias
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