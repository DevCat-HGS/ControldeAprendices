import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api';
  bool _isLoading = false;
  String? _token;
  String? _userId;
  String? _userRole;
  String? _userName;

  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get userId => _userId;
  String? get userRole => _userRole;
  String? get userName => _userName;

  bool get isAuthenticated => _token != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _token = data['token'];
          _userId = data['user']['_id'];
          _userRole = data['user']['role'];
          _userName = data['user']['name'];

          // Guardar datos en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await prefs.setString('userId', _userId!);
          await prefs.setString('userRole', _userRole!);
          await prefs.setString('userName', _userName!);

          return true;
        }
        return false;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : 'Error de conexión');
    }
  }

  Future<Map<String, dynamic>> register(String firstName, String lastName, String documentNumber, 
      String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': '$firstName $lastName',
          'email': email,
          'password': password,
          'documentType': 'CC',
          'documentNumber': documentNumber,
          'role': role,
        }),
      );

      _isLoading = false;
      notifyListeners();

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _token = responseData['token'];
        _userId = responseData['user']['_id'];
        _userRole = responseData['user']['role'];
        _userName = responseData['user']['name'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userId', _userId!);
        await prefs.setString('userRole', _userRole!);
        await prefs.setString('userName', _userName!);

        return {'success': true, 'user': responseData['user']};
      } else {
        // Si el servidor responde con un código de error, extraemos el mensaje de error
        final errorMessage = responseData['error'] ?? 
                           (response.statusCode == 400 ? 'Datos inválidos o usuario ya existe' : 'Error al registrar');
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Solo devolvemos error de conexión si realmente es un error de red
      return {'success': false, 'error': e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : 'Error de conexión al servidor'};
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return false;
    }

    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _userRole = prefs.getString('userRole');
    _userName = prefs.getString('userName');

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userRole = null;
    _userName = null;

    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    notifyListeners();
  }
}