import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled1/services/auth_service.dart';
import 'package:untitled1/services/attendance_service.dart';
import 'package:untitled1/services/course_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourse;
  List<Map<String, dynamic>> _students = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingCourses = true;
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courseService = Provider.of<CourseService>(context, listen: false);
    final courses = await courseService.getCourses();
    
    setState(() {
      _courses = courses;
      _isLoadingCourses = false;
    });
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;
    
    setState(() {
      _isLoadingStudents = true;
      _students = [];
    });

    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
    final students = await attendanceService.getStudentsByCourse(_selectedCourse!);
    
    setState(() {
      _students = students.map((student) => {
        ...student,
        'present': false,
      }).toList();
      _isLoadingStudents = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
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
  }

  void _toggleAttendance(int index) {
    setState(() {
      _students[index]['present'] = !_students[index]['present'];
    });
  }

  void _saveAttendance() async {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un curso')),
      );
      return;
    }

    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay estudiantes para registrar asistencia')),
      );
      return;
    }

    setState(() {
      _isLoadingStudents = true;
    });

    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
    final attendanceData = _students.map((student) => {
      'studentId': student['_id'] ?? student['id'],
      'present': student['present'],
    }).toList();

    final success = await attendanceService.saveAttendance(
      _selectedCourse!,
      _selectedDate,
      attendanceData,
    );

    setState(() {
      _isLoadingStudents = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asistencia guardada correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la asistencia')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registro de Asistencia',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Selector de curso
          _isLoadingCourses
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Curso',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  value: _selectedCourse,
                  hint: const Text('Selecciona un curso'),
                  items: _courses.map((course) {
                    return DropdownMenuItem<String>(
                      value: course['_id'],
                      child: Text(course['name']),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCourse = newValue;
                    });
                    _loadStudents();
                  },
                ),
          const SizedBox(height: 16),
          // Selector de fecha
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Lista de estudiantes
          Expanded(
            child: _isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const Center(child: Text('No hay estudiantes en este curso'))
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: CheckboxListTile(
                              title: Text('${student['firstName']} ${student['lastName']}'),
                              subtitle: Text('Documento: ${student['documentNumber']}'),
                              value: student['present'],
                              onChanged: (_) => _toggleAttendance(index),
                              activeColor: Colors.green,
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
          // Botón para guardar asistencia
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAttendance,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar Asistencia', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );