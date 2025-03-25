import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/evaluation_service.dart';
import '../services/course_service.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({Key? key}) : super(key: key);

  @override
  _EvaluationPageState createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  final EvaluationService _evaluationService = EvaluationService();
  final CourseService _courseService = CourseService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _evaluations = [];
  String? _selectedCourseId;
  String? _userRole;
  String? _userId;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scoreController = TextEditingController();
  final _feedbackController = TextEditingController();
  DateTime _evaluationDate = DateTime.now();

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

  Future<void> _loadEvaluations() async {
    if (_selectedCourseId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final evaluations = _userRole == 'instructor'
          ? await _evaluationService.getCourseEvaluations(_selectedCourseId!)
          : await _evaluationService.getStudentEvaluations(_selectedCourseId!, _userId!);
      setState(() {
        _evaluations = evaluations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar las evaluaciones')),
      );
    }
  }

  Future<void> _createEvaluation() async {
    if (_selectedCourseId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _evaluationService.createEvaluation({
        'course': _selectedCourseId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'score': double.parse(_scoreController.text),
        'feedback': _feedbackController.text,
        'evaluationDate': _evaluationDate.toIso8601String(),
        'userId': _userId,
      });

      _titleController.clear();
      _descriptionController.clear();
      _scoreController.clear();
      _feedbackController.clear();

      await _loadEvaluations();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluación creada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear la evaluación')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildEvaluationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Título',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _scoreController,
          decoration: const InputDecoration(
            labelText: 'Puntaje Máximo',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _feedbackController,
          decoration: const InputDecoration(
            labelText: 'Retroalimentación',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Fecha de Evaluación'),
          subtitle: Text(
            '${_evaluationDate.day}/${_evaluationDate.month}/${_evaluationDate.year}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _evaluationDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null && picked != _evaluationDate) {
                setState(() {
                  _evaluationDate = picked;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _createEvaluation,
          child: const Text('Crear Evaluación'),
        ),
      ],
    );
  }

  Widget _buildEvaluationList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _evaluations.length,
      itemBuilder: (context, index) {
        final evaluation = _evaluations[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(evaluation['title']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evaluation['description']),
                Text('Puntaje: ${evaluation['score']}'),
                if (evaluation['feedback'] != null)
                  Text('Retroalimentación: ${evaluation['feedback']}'),
              ],
            ),
            trailing: Text(
              evaluation['evaluationDate'] != null
                  ? evaluation['evaluationDate'].toString().split('T')[0]
                  : '',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluaciones'),
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
                    items: _courses.map<DropdownMenuItem<String>>((course) {
                      return DropdownMenuItem<String>(
                        value: course['_id'] as String,
                        child: Text(course['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCourseId = value;
                      });
                      _loadEvaluations();
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_userRole == 'instructor' && _selectedCourseId != null) ...[                    
                    _buildEvaluationForm(),
                    const Divider(height: 32),
                  ],
                  if (_selectedCourseId != null) ...[                    
                    const Text(
                      'Evaluaciones del Curso',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildEvaluationList(),
                  ],
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }
}