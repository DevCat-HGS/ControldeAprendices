import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api';
  Map<String, dynamic> _userProfile = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  Map<String, dynamic> get userProfile => _userProfile;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _updateLocalProfile(Map<String, dynamic> userData) {
    _userProfile = {
      'name': userData['name'] ?? 'Sin nombre',
      'lastName': userData['lastName'] ?? 'Sin apellido',
      'email': userData['email'] ?? 'Sin correo',
      'documentNumber': userData['documentNumber'] ?? 'Sin documento',
      'role': userData['role'] ?? 'Sin rol',
      'courses': userData['courses'] ?? [],
      'evaluations': userData['evaluations'] ?? [],
      'attendance': userData['attendance'] ?? []
    };
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': 'No se encontró el token de autenticación',
          'profile': _userProfile
        };
      }

      // Obtener datos del perfil
      final profileResponse = await http.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      // Obtener datos adicionales (cursos, evaluaciones, asistencias)
      final coursesResponse = await http.get(
        Uri.parse('$_baseUrl/courses/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      final evaluationsResponse = await http.get(
        Uri.parse('$_baseUrl/evaluations/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      final attendanceResponse = await http.get(
        Uri.parse('$_baseUrl/attendance/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      final Map<String, dynamic> profileData = json.decode(profileResponse.body);
      final Map<String, dynamic> coursesData = json.decode(coursesResponse.body);
      final Map<String, dynamic> evaluationsData = json.decode(evaluationsResponse.body);
      final Map<String, dynamic> attendanceData = json.decode(attendanceResponse.body);

      if (profileResponse.statusCode == 200 && profileData['success'] && profileData['data'] != null) {
        final userData = profileData['data'];
        userData['courses'] = coursesData['data'] ?? [];
        userData['evaluations'] = evaluationsData['data'] ?? [];
        userData['attendance'] = attendanceData['data'] ?? [];
        _updateLocalProfile(userData);
      } else {
        _updateLocalProfile({});
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': profileResponse.statusCode == 200,
        'message': profileData['message'] ?? 'Error al obtener el perfil',
        'profile': _userProfile,
      };
    } catch (e) {
      _isLoading = false;
      _userProfile = {
        'name': 'Sin nombre',
        'lastName': 'Sin apellido',
        'email': 'Sin correo',
        'documentNumber': 'Sin documento',
        'role': 'Sin rol'
      };
      notifyListeners();
      return {
        'success': false,
        'message': 'Error de conexión',
        'profile': _userProfile
      };
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No se encontró el token de autenticación',
        };
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(profileData),
      );

      final Map<String, dynamic> decodedResp = json.decode(response.body);
      if (response.statusCode == 200 && decodedResp['data'] != null) {
        final userData = decodedResp['data'];
        _userProfile = {
          'name': userData['name'],
          'lastName': userData['lastName'],
          'email': userData['email'],
          'documentNumber': userData['documentNumber'],
          'role': userData['role']
        };
        notifyListeners();
      }

      return {
        'success': response.statusCode == 200,
        'message': decodedResp['message'] ?? 'Perfil actualizado correctamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión',
      };
    }
  }

  Future<Map<String, dynamic>> getStudentSummary(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/summary'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> decodedResp = json.decode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': decodedResp['message'] ?? 'Error al obtener el resumen',
        'summary': decodedResp['summary'] ?? {},
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión',
      };
    }
  }
}