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

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      final Map<String, dynamic> decodedResp = json.decode(response.body);
      if (response.statusCode == 200 && decodedResp['success'] && decodedResp['data'] != null) {
        final userData = decodedResp['data'];
        _userProfile = {
          'name': userData['name'] ?? 'Sin nombre',
          'lastName': userData['lastName'] ?? 'Sin apellido',
          'email': userData['email'] ?? 'Sin correo',
          'documentNumber': userData['documentNumber'] ?? 'Sin documento',
          'role': userData['role'] ?? 'Sin rol'
        };
      } else {
        _userProfile = {
          'name': 'Sin nombre',
          'lastName': 'Sin apellido',
          'email': 'Sin correo',
          'documentNumber': 'Sin documento',
          'role': 'Sin rol'
        };
      }

      _isLoading = false;
      notifyListeners();
      return {
        'success': response.statusCode == 200,
        'message': decodedResp['message'] ?? 'Error al obtener el perfil',
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