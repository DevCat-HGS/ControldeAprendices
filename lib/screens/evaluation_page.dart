import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:untitled1/services/auth_service.dart';
import 'package:untitled1/services/evaluation_service.dart';
import 'package:untitled1/services/course_service.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({super.key});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourse;
  String? _selectedCourseId;

  // Lista de evaluaciones desde la API
  List<Map<String, dynamic>> _evaluations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Cargar cursos
    final courseService = Provider.of<CourseService>(context, listen: false);
    final courses = await courseService.getCourses();
    
    // Cargar evaluaciones
    final evaluationService = Provider.of<EvaluationService>(context, listen: false);
    final evaluations = await evaluationService.getEvaluations();
    
    setState(() {
      _courses = courses;
      _evaluations = evaluations;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _createEvaluation() async {
    if (_formKey.currentState!.validate() && _selectedCourseId != null) {
      // Crear la evaluación usando el servicio de API
      setState(() {
        _isLoading = true;
      });
      
      final evaluationService = Provider.of<EvaluationService>(context, listen: false);
      final evaluationData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'dueDate': _dueDate.toIso8601String(),
        'maxScore': int.parse(_maxScoreController.text),
        'courseId': _selectedCourseId,
      };
      
      final success = await evaluationService.createEvaluation(evaluationData);
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        // Limpiar el formulario
        _nameController.clear();
        _descriptionController.clear();
        _maxScoreController.clear();
        setState(() {
          _selectedCourse = null;
          _selectedCourseId = null;
        });
        
        // Recargar las evaluaciones
        _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluación creada correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear la evaluación')),
        );
      }
    } else if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un curso')),
      );
    }
  }

  Widget _buildInstructorView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crear Nueva Evaluación',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Nombre de la evaluación
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la evaluación',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Puntaje máximo
              TextFormField(
                controller: _maxScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Puntaje máximo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un puntaje máximo';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Selector de curso
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Curso',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCourseId,
                hint: const Text('Selecciona un curso'),
                items: _courses.map((Map<String, dynamic> course) {
                  return DropdownMenuItem<String>(
                    value: course['_id'],
                    child: Text(course['name']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  final selectedCourse = _courses.firstWhere(
                    (course) => course['_id'] == newValue,
                    orElse: () => {},
                  );
                  setState(() {
                    _selectedCourseId = newValue;
                    _selectedCourse = selectedCourse['name'];
                  });
                },
              ),
              const SizedBox(height: 16),
              // Selector de fecha de entrega
              InkWell(
                onTap: () => _selectDueDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de entrega',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_dueDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botón para crear evaluación
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createEvaluation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Crear Evaluación', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Evaluaciones Creadas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Expanded(
              child: _evaluations.isEmpty
                ? const Center(child: Text('No hay evaluaciones disponibles'))
                : ListView.builder(
                    itemCount: _evaluations.length,
                    itemBuilder: (context, index) {
                      final evaluation = _evaluations[index];
                      // Convertir la fecha de string a DateTime
                      final dueDate = DateTime.parse(evaluation['dueDate']);
                      // Buscar el nombre del curso por su ID
                      final course = _courses.firstWhere(
                        (c) => c['_id'] == evaluation['courseId'],
                        orElse: () => {'name': 'Curso no encontrado'},
                      );
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(evaluation['name']),
                          subtitle: Text(
                            '${course['name']} - Entrega: ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                          ),
                          trailing: Text('${evaluation['maxScore']} pts'),
                          onTap: () {
                            // Mostrar detalles de la evaluación
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(evaluation['name']),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Descripción: ${evaluation['description']}'),
                                    const SizedBox(height: 8),
                                    Text('Curso: ${course['name']}'),
                                    const SizedBox(height: 8),
                                    Text('Fecha de entrega: ${DateFormat('dd/MM/yyyy').format(dueDate)}'),
                                    const SizedBox(height: 8),
                                    Text('Puntaje máximo: ${evaluation['maxScore']} pts'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              ),
                            );
                          }