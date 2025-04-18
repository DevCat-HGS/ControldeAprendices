import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../services/evaluation_service.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({Key? key}) : super(key: key);

  @override
  _EvaluationPageState createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  List<dynamic> _courses = [];
  List<dynamic> _evaluations = [];
  dynamic _selectedCourse;
  String? _userRole;
  String? _selectedFile;
  bool _isUploading = false;
  String? _error;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al seleccionar el archivo')),
      );
    }
  }

  Future<void> _uploadEvidence(String evaluationId) async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un archivo')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final evaluationService = Provider.of<EvaluationService>(context, listen: false);
      final result = await evaluationService.uploadEvidence(
        evaluationId,
        _selectedFile!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        setState(() {
          _selectedFile = null;
        });
        if (_selectedCourse != null) {
          _loadEvaluations(_selectedCourse['_id']);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la evidencia')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Controladores para el formulario de creación de evaluación
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  // Controlador para la subida de evidencias
  final _evidenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _loadCourses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _getUserRole() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _userRole = authService.userRole;
    });
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courseService = Provider.of<CourseService>(context, listen: false);
      final success = await courseService.getCourses();
      
      if (success) {
        setState(() {
          _courses = courseService.courses;
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

  Future<void> _loadEvaluations([String? courseId]) async {
    if (courseId == null && _selectedCourse == null) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final evaluationService = Provider.of<EvaluationService>(context, listen: false);
      final evaluations = await evaluationService.getEvaluationsByCourse(courseId ?? _selectedCourse!['_id']);
      
      if (evaluations != null) {
        setState(() {
          _evaluations = evaluations;
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar las evaluaciones');
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

  Future<void> _createEvaluation() async {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un curso')),
      );
      return;
    }

    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    try {
      setState(() => _isLoading = true);
      final evaluationService = Provider.of<EvaluationService>(context, listen: false);
      
      final evaluationData = {
        'name': _nameController.text.trim(),
        'course': _selectedCourse['_id'],
        'description': _descriptionController.text.trim(),
        'maxScore': int.parse(_maxScoreController.text),
        'dueDate': _dueDate.toIso8601String(),
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
        _dueDate = DateTime.now().add(const Duration(days: 7));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluación creada correctamente')),
        );
        
        // Recargar las evaluaciones
        _loadEvaluations(_selectedCourse['_id']);
      } else {
        throw Exception('Error al crear la evaluación');
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

  Future<void> _submitEvidence(String evaluationId) async {
    if (_evidenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese una URL o descripción de la evidencia')),
      );
      return;
    }

    if (!mounted) return;

    try {
      setState(() => _isLoading = true);
      final evaluationService = Provider.of<EvaluationService>(context, listen: false);
      
      final evidenceData = {
        'evidence': _evidenceController.text.trim(),
      };
      
      final success = await evaluationService.submitEvidence(evaluationId, evidenceData);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _evidenceController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evidencia enviada correctamente')),
        );
        // Recargar las evaluaciones
        _loadEvaluations(_selectedCourse['_id']);
      } else {
        throw Exception('Error al enviar la evidencia');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Evaluaciones'),
      ),
      body: _isLoading
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
                        _loadEvaluations(value['_id']);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Sección para instructores: Crear evaluación
                  if (_userRole == 'instructor' && _selectedCourse != null) ...[  
                    const Text(
                      'Crear Nueva Evaluación',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Formulario de creación de evaluación
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la Evaluación',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese el nombre de la evaluación';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _maxScoreController,
                            decoration: const InputDecoration(
                              labelText: 'Puntaje Máximo',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                    
                           // Selector de fecha de entrega
                           InkWell(
                             onTap: () async {
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
                             },
                             child: InputDecorator(
                               decoration: const InputDecoration(
                                 labelText: 'Fecha de Entrega',
                                 border: OutlineInputBorder(),
                               ),
                               child: Text(
                                 DateFormat('dd/MM/yyyy').format(_dueDate),
                               ),
                             ),
                           ),
                           const SizedBox(height: 16),
                           
                           // Botón para crear evaluación
                           SizedBox(
                             width: double.infinity,
                             child: ElevatedButton(
                               onPressed: _createEvaluation,
                               child: const Text('Crear Evaluación'),
                             ),
                           ),
                         ],
                       ),
                     ),
                     const Divider(height: 32),
                  ],
                  
                  // Lista de evaluaciones
                  if (_selectedCourse != null) ...[  
                    const Text(
                      'Evaluaciones Asignadas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_evaluations.isEmpty)
                      const Text('No hay evaluaciones asignadas para este curso')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _evaluations.length,
                        itemBuilder: (context, index) {
                          final evaluation = _evaluations[index];
                          final bool isPastDue = DateTime.parse(evaluation['dueDate']).isBefore(DateTime.now());
                          
                          // Buscar si el usuario actual tiene una calificación
                          final authService = Provider.of<AuthService>(context, listen: false);
                          final userId = authService.userId;
                          final userGrade = evaluation['grades']?.firstWhere(
                            (grade) => grade['student'] == userId,
                            orElse: () => null,
                          );
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    evaluation['name'],
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(evaluation['description']),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.score, size: 16),
                                      const SizedBox(width: 4),
                                      Text('Puntaje máximo: ${evaluation['maxScore']}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Fecha de entrega: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(evaluation['dueDate']))}',
                                        style: TextStyle(
                                          color: isPastDue ? Colors.red : null,
                                          fontWeight: isPastDue ? FontWeight.bold : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Mostrar calificación si existe
                                  if (userGrade != null) ...[  
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.grade, size: 16, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tu calificación: ${userGrade['score']}/${evaluation['maxScore']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    if (userGrade['feedback'] != null && userGrade['feedback'].isNotEmpty) ...[  
                                      const SizedBox(height: 4),
                                      Text('Retroalimentación: ${userGrade['feedback']}'),
                                    ],
                                    if (userGrade['evidence'] != null && userGrade['evidence'].isNotEmpty) ...[  
                                      const SizedBox(height: 4),
                                      Text('Evidencia enviada: ${userGrade['evidence']}'),
                                    ],
                                  ],
                                  
                                  // Para aprendices: Formulario para subir evidencia
                                  if (_userRole == 'aprendiz' && 
                                      (userGrade == null || userGrade['evidence'] == null || userGrade['evidence'].isEmpty)) ...[  
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Subir Evidencia:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _evidenceController,
                                            decoration: const InputDecoration(
                                              labelText: 'URL o descripción de la evidencia',
                                              border: OutlineInputBorder(),
                                              hintText: 'Ingrese un enlace o descripción de su trabajo',
                                            ),
                                            maxLines: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: _pickFile,
                                          icon: const Icon(Icons.attach_file),
                                          tooltip: 'Adjuntar archivo',
                                        ),
                                      ],
                                    ),
                                    if (_selectedFile != null) ...[  
                                      const SizedBox(height: 8),
                                      Text(
                                        'Archivo seleccionado: ${_selectedFile!.split('/').last}',
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isUploading
                                            ? null
                                            : () => _selectedFile != null
                                                ? _uploadEvidence(evaluation['_id'])
                                                : _submitEvidence(evaluation['_id']),
                                        child: Text(_isUploading
                                            ? 'Subiendo...'
                                            : _selectedFile != null
                                                ? 'Subir Archivo'
                                                : 'Enviar Evidencia'),
                                      ),
                                    ),
                                  ],
                                  
                                  // Para instructores: Opciones de gestión
                                  if (_userRole == 'instructor') ...[  
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(Icons.people),
                                          label: const Text('Ver Entregas'),
                                          onPressed: () {
                                            // Navegar a una página de detalle de entregas
                                            // Implementación futura
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Editar'),
                                          onPressed: () {
                                            // Implementación futura: editar evaluación
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}