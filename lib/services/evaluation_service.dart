import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EvaluationService extends ChangeNotifier {
  final String _baseUrl = 'http://localhost:3000/api';
  bool _isLoading = false;
  List<dynamic> _evaluations = [];

  bool get isLoading => _isLoading;
  List<dynamic> get evaluations => _evaluations;

  // Obtener el token almacenado
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Obtener todas las evaluaciones
  Future<bool> getEvaluations() async {
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
        Uri.parse('$_baseUrl/evaluations'),
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
          _evaluations = data['data'];
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

  // Obtener evaluaciones por curso
  Future<List<dynamic>?> getEvaluationsByCourse(String courseId) async {
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
        Uri.parse('$_baseUrl/evaluations/course/$courseId'),
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

  // Obtener una evaluación específica
  Future<Map<String, dynamic>?> getEvaluation(String evaluationId) async {
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
        Uri.parse('$_baseUrl/evaluations/$evaluationId'),
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

  // Crear una nueva evaluación (solo para instructores)
  Future<bool> createEvaluation(Map<String, dynamic> evaluationData) async {
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
        Uri.parse('$_baseUrl/evaluations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(evaluationData),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        await getEvaluations(); // Actualizar la lista de evaluaciones
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar una evaluación existente (solo para instructores)
  Future<bool> updateEvaluation(String evaluationId, Map<String, dynamic> evaluationData) async {
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
        Uri.parse('$_baseUrl/evaluations/$evaluationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(evaluationData),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        await getEvaluations(); // Actualizar la lista de evaluaciones
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar una evaluación (solo para instructores)
  Future<bool> deleteEvaluation(String evaluationId) async {
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
        Uri.parse('$_baseUrl/evaluations/$evaluationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        await getEvaluations(); // Actualizar la lista de evaluaciones
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Agregar una calificación a una evaluación (solo para instructores)
  Future<bool> addGrade(String evaluationId, Map<String, dynamic> gradeData) async {
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
        Uri.parse('$_baseUrl/evaluations/$evaluationId/grades'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(gradeData),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar una calificación existente (solo para instructores)
  Future<bool> updateGrade(String evaluationId, String studentId, Map<String, dynamic> gradeData) async {
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
        Uri.parse('$_baseUrl/evaluations/$evaluationId/grades/$studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(gradeData),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Subir evidencia para una evaluación (para aprendices)
  Future<Map<String, dynamic>> uploadEvidence(String evaluationId, String filePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'No se encontró el token de autenticación'};
      }

      // Crear un request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/evaluations/$evaluationId/evidence')
      );

      // Agregar el archivo
      request.files.add(await http.MultipartFile.fromPath('evidence', filePath));

      // Agregar headers
      request.headers.addAll({
        'Authorization': 'Bearer $token'
      });

      // Enviar la petición
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Evidencia subida correctamente'
        };
      }

      return {
        'success': false,
        'message': 'Error al subir la evidencia'
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Error: ${e.toString()}'
      };
    }
  }

  // Enviar evidencia como texto o URL (para aprendices)
  Future<bool> submitEvidence(String evaluationId, Map<String, dynamic> evidenceData) async {
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
        Uri.parse('$_baseUrl/evaluations/$evaluationId/evidence'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(evidenceData),
      );

      _isLoading = false;
      notifyListeners();

      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

}