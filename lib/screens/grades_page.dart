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
    final courseService = Provider.of<CourseService>(context, listen: false);
    await courseService.getCourses();

    if (courseService.courses.isNotEmpty) {
      setState(() {
        _selectedCourseId = courseService.courses[0]['_id'];
      });
      _loadGrades();
    }
  }

  Future<void> _loadGrades() async {
    if (_selectedCourseId == null) return;

    final gradesService = Provider.of<GradesService>(context, listen: false);
    await gradesService.getCourseGrades(_selectedCourseId!);
  }

  void _showEditGradeDialog(Map<String, dynamic> grade) {
    _gradeController.text = grade['score'].toString();
    _commentController.text = grade['comments'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final gradesService = Provider.of<GradesService>(context, listen: false);
              final result = await gradesService.updateGrade(
                grade['_id'],
                {
                  'score': double.tryParse(_gradeController.text) ?? 0.0,
                  'comments': _commentController.text,
                },
              );

              if (!mounted) return;

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'])),
              );
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
      body: Padding(
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
              child: gradesService.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : gradesService.grades.isEmpty
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