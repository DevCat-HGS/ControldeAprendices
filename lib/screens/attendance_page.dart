import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final String _baseUrl = 'http://localhost:3000/api';
  bool _isLoading = true;
  List<dynamic> _courses = [];
  List<dynamic> _students = [];
  Map<String, bool> _attendanceStatus = {};
  dynamic _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _attendanceHistory = [];
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.get(
        Uri.parse('$_baseUrl/courses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _courses = data['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar los cursos');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadStudents(String courseId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.get(
        Uri.parse('$_baseUrl/courses/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _students = data['data']['students'];
          _attendanceStatus = {};
          // Inicializar el estado de asistencia para cada estudiante
          for (var student in _students) {
            _attendanceStatus[student['_id']] = false;
          }
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar los estudiantes');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un curso')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Preparar los registros de asistencia
      List<Map<String, dynamic>> records = [];
      _attendanceStatus.forEach((studentId, present) {
        records.add({
          'student': studentId,
          'present': present,
        });
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/attendance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
        body: json.encode({
          'course': _selectedCourse['_id'],
          'date': _selectedDate.toIso8601String(),
          'records': records,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asistencia registrada correctamente')),
        );
        // Recargar los estudiantes para actualizar la vista
        _loadStudents(_selectedCourse['_id']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al registrar la asistencia');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadAttendanceHistory(String courseId, [String? studentId]) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      String url = '$_baseUrl/attendance?course=$courseId';
      if (studentId != null) {
        url += '&student=$studentId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _attendanceHistory = data['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar el historial de asistencia');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registro de Asistencia'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Registrar Asistencia'),
              Tab(text: 'Historial de Asistencia'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAttendanceRegistrationTab(),
            _buildAttendanceHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceRegistrationTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de curso
                DropdownButtonFormField<dynamic>(
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Curso',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCourse,
                  items: _courses.map((course) {
                    return DropdownMenuItem(
                      value: course,
                      child: Text(course['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourse = value;
                    });
                    if (value != null) {
                      _loadStudents(value['_id']);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Selector de fecha
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2025),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Lista de estudiantes
                if (_selectedCourse != null) ...[  
                  const Text(
                    'Lista de Estudiantes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_students.isEmpty)
                    const Text('No hay estudiantes inscritos en este curso')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentId = student['_id'];
                        return CheckboxListTile(
                          title: Text('${student['name']} ${student['lastName']}'),
                          subtitle: Text(student['email']),
                          value: _attendanceStatus[studentId],
                          onChanged: (bool? value) {
                            setState(() {
                              _attendanceStatus[studentId] = value ?? false;
                            });
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  
                  // Botón para guardar asistencia
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAttendance,
                      child: const Text('Guardar Asistencia'),
                    ),
                  ),
                ],
              ],
            ),
          );
  }

  Widget _buildAttendanceHistoryTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de curso
                DropdownButtonFormField<dynamic>(
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Curso',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCourse,
                  items: _courses.map((course) {
                    return DropdownMenuItem(
                      value: course,
                      child: Text(course['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourse = value;
                      _selectedStudentId = null;
                    });
                    if (value != null) {
                      _loadStudents(value['_id']);
                      _loadAttendanceHistory(value['_id']);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Selector de estudiante (opcional)
                if (_selectedCourse != null && _students.isNotEmpty) ...[  
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Estudiante (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedStudentId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos los estudiantes'),
                      ),
                      ..._students.map((student) {
                        return DropdownMenuItem<String?>(
                          value: student['_id'],
                          child: Text('${student['name']} ${student['lastName']}'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStudentId = value;
                      });
                      _loadAttendanceHistory(_selectedCourse['_id'], value);
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Historial de asistencia
                  const Text(
                    'Historial de Asistencia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_attendanceHistory.isEmpty)
                    const Text('No hay registros de asistencia para este curso')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attendanceHistory.length,
                      itemBuilder: (context, index) {
                        final attendance = _attendanceHistory[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(attendance['date']))}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text('Estudiantes presentes:'),
                                const SizedBox(height: 4),
                                ...attendance['records']
                                    .where((record) => record['present'] == true)
                                    .map<Widget>((record) {
                                  final student = _students.firstWhere(
                                    (s) => s['_id'] == record['student'],
                                    orElse: () => {'name': 'Desconocido', 'lastName': ''},
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Text('- ${student['name']} ${student['lastName']}'),
                                  );
                                }).toList(),
                                const SizedBox(height: 8),
                                const Text('Estudiantes ausentes:'),
                                const SizedBox(height: 4),
                                ...attendance['records']
                                    .where((record) => record['present'] == false)
                                    .map<Widget>((record) {
                                  final student = _students.firstWhere(
                                    (s) => s['_id'] == record['student'],
                                    orElse: () => {'name': 'Desconocido', 'lastName': ''},
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Text('- ${student['name']} ${student['lastName']}'),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ],
            ),
          );
  }
}