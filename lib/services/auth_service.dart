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
        if (data['success'] == true && data['data'] != null) {
          final user = data['data'];
          _token = user['token'];
          _userId = user['_id'];
          _userRole = user['role'];
          _userName = user['name'];
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
          'name': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'documentNumber': documentNumber,
          'role': role,
        }),
      );

      _isLoading = false;
      notifyListeners();

      final responseData = json.decode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['success'] == true) {
        final user = responseData['data'];
        if (user == null || user['_id'] == null) {
          return {'success': false, 'error': 'Datos de usuario incompletos en la respuesta del servidor'};
        }
        _token = user['token'];
        _userId = user['_id'];
        _userRole = user['role'];
        _userName = user['name'];

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
      
      // Identificar el tipo de error para dar un mensaje más preciso
      String errorMessage;
      if (e is http.ClientException) {
        // Error específico de cliente HTTP (problemas de conexión)
        errorMessage = 'No se pudo conectar al servidor. Verifique su conexión a internet.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        // Error de socket o conexión rechazada
        errorMessage = 'No se pudo establecer conexión con el servidor. Verifique que el servidor esté en ejecución.';
      } else if (e.toString().contains('timeout')) {
        // Error de tiempo de espera
        errorMessage = 'La conexión al servidor ha excedido el tiempo de espera. Intente nuevamente.';
      } else if (e.toString().contains('Exception:')) {
        // Extraer mensaje de excepción personalizado
        errorMessage = e.toString().split('Exception: ')[1];
      } else {
        // Otro tipo de error
        errorMessage = 'Error inesperado: ${e.toString()}';
      }
      
      return {'success': false, 'error': errorMessage};
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