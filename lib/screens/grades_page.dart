import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/grades_service.dart';
import '../services/course_service.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({Key? key}) : super(key: key);

  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  String? _selectedCourseId;
  final _gradeController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);
      final courseService = Provider.of<CourseService>(context, listen: false);
      await courseService.getCourses();

      if (courseService.courses.isNotEmpty) {
        _selectedCourseId = courseService.courses[0]['_id'];
        await _loadGrades();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar los datos iniciales'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadGrades() async {
    if (_selectedCourseId == null) return;

    try {
      setState(() => _isLoading = true);
      final gradesService = Provider.of<GradesService>(context, listen: false);
      await gradesService.getCourseGrades(_selectedCourseId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar las calificaciones'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditGradeDialog(Map<String, dynamic> grade) {
    _gradeController.text = grade['score'].toString();
    _commentController.text = grade['comments'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Editar Calificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: 'Calificación',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comentarios',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (_gradeController.text.isEmpty) {
                  throw Exception('La calificación no puede estar vacía');
                }

                final score = double.tryParse(_gradeController.text);
                if (score == null || score < 0 || score > 100) {
                  throw Exception('La calificación debe ser un número válido entre 0 y 100');
                }

                setState(() => _isLoading = true);
                final gradesService = Provider.of<GradesService>(context, listen: false);
                final result = await gradesService.updateGrade(
                  grade['_id'],
                  {
                    'score': score,
                    'comments': _commentController.text.trim(),
                  },
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);
                await _loadGrades();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['success'] ? 'Calificación actualizada correctamente' : result['message']),
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final courseService = Provider.of<CourseService>(context);
    final gradesService = Provider.of<GradesService>(context);
    final isInstructor = authService.userRole == 'instructor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Calificaciones'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de curso
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Curso',
                border: OutlineInputBorder(),
              ),
              items: courseService.courses.map((dynamic courseData) {
                final course = courseData as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: course['_id'],
                  child: Text(course['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCourseId = value;
                });
                _loadGrades();
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Calificaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: gradesService.grades.isEmpty
                      ? const Center(child: Text('No hay calificaciones disponibles'))
                      : ListView.builder(
                          itemCount: gradesService.grades.length,
                          itemBuilder: (context, index) {
                            final grade = gradesService.grades[index];
                            return Card(
                              child: ListTile(
                                title: Text(grade['evaluationName'] ?? 'Evaluación sin nombre'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Estudiante: ${grade['studentName']}'),
                                    Text('Calificación: ${grade['score']}'),
                                    if (grade['comments'] != null)
                                      Text('Comentarios: ${grade['comments']}'),
                                  ],
                                ),
                                trailing: isInstructor
                                    ? IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditGradeDialog(grade),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}