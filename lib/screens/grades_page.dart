import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/grade_service.dart';
import '../services/course_service.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({Key? key}) : super(key: key);

  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  final GradeService _gradeService = GradeService();
  final CourseService _courseService = CourseService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _grades = [];
  String? _selectedCourseId;
  String? _userRole;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole');
      _userId = prefs.getString('userId');
    });
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = _userRole == 'instructor'
          ? await _courseService.getInstructorCourses()
          : await _courseService.getStudentCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar los cursos')),
      );
    }
  }

  Future<void> _loadGrades() async {
    if (_selectedCourseId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final grades = _userRole == 'instructor'
          ? await _gradeService.getCourseGrades(_selectedCourseId!)
          : await _gradeService.getStudentGrades(_selectedCourseId!, _userId!);
      setState(() {
        _grades = grades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar las calificaciones')),
      );
    }
  }

  Widget _buildGradesList() {
    if (_grades.isEmpty) {
      return const Center(
        child: Text('No hay calificaciones disponibles'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _grades.length,
      itemBuilder: (context, index) {
        final grade = _grades[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(grade['evaluationTitle'] ?? 'Sin título'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calificación: ${grade['score']}/${grade['maxScore']}'),
                if (grade['feedback'] != null && grade['feedback'].isNotEmpty)
                  Text('Retroalimentación: ${grade['feedback']}'),
                Text('Fecha: ${grade['date'].toString().split('T')[0]}'),
              ],
            ),
            trailing: _userRole == 'instructor'
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditGradeDialog(grade),
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _showEditGradeDialog(Map<String, dynamic> grade) async {
    final scoreController = TextEditingController(
        text: grade['score'].toString());
    final feedbackController = TextEditingController(
        text: grade['feedback'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Calificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: scoreController,
              decoration: InputDecoration(
                labelText: 'Calificación (máx: ${grade['maxScore']})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Retroalimentación',
                border: OutlineInputBorder(),
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
          ElevatedButton(
            onPressed: () async {
              try {
                await _gradeService.updateGrade(
                  grade['_id'],
                  double.parse(scoreController.text),
                  feedbackController.text,
                );
                if (!mounted) return;
                Navigator.pop(context);
                _loadGrades();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Calificación actualizada correctamente')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Error al actualizar la calificación')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    scoreController.dispose();
    feedbackController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificaciones'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Curso',
                      border: OutlineInputBorder(),
                    ),
                    items: _courses.map((course) {
                      return DropdownMenuItem(
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
                  if (_selectedCourseId != null) ...[                    
                    const Text(
                      'Historial de Calificaciones',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildGradesList(),
                  ],
                ],
              ),
            ),
    );
  }
}