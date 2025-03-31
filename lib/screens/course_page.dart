import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import '../services/auth_service.dart';
import 'available_courses_page.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({Key? key}) : super(key: key);

  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  
  String? _selectedCourseId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Cargar los cursos al iniciar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseService>(context, listen: false).getCourses();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _codeController.clear();
    setState(() {
      _selectedCourseId = null;
      _isEditing = false;
    });
  }

  void _editCourse(Map<String, dynamic> course) {
    setState(() {
      _selectedCourseId = course['_id'];
      _nameController.text = course['name'];
      _descriptionController.text = course['description'] ?? '';
      _codeController.text = course['code'] ?? '';
      _isEditing = true;
    });
  }

  Future<void> _saveCourse() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor seleccione las fechas de inicio y fin')),
        );
        return;
      }

      final courseData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'code': _codeController.text,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
      };

      final courseService = Provider.of<CourseService>(context, listen: false);
      Map<String, dynamic> result;

      if (_isEditing && _selectedCourseId != null) {
        // Actualizar curso existente
        result = await courseService.updateCourse(_selectedCourseId!, courseData);
      } else {
        // Crear nuevo curso
        result = await courseService.createCourse(courseData);
      }

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? (_isEditing ? 'Curso actualizado con éxito' : 'Curso creado con éxito'))),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error al guardar el curso')),
        );
      }
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    final courseService = Provider.of<CourseService>(context, listen: false);
    final result = await courseService.deleteCourse(courseId);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Curso eliminado con éxito')),
      );
      if (_selectedCourseId == courseId) {
        _resetForm();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Error al eliminar el curso')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseService = Provider.of<CourseService>(context);
    final authService = Provider.of<AuthService>(context);
    final isInstructor = authService.userRole == 'instructor';

    return Scaffold(
      appBar: AppBar(
        title: Text(isInstructor ? 'Gestión de Cursos' : 'Mis Cursos'),
        actions: [
          if (!isInstructor)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Inscribirse a cursos',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AvailableCoursesPage()),
                ).then((_) {
                  // Recargar los cursos al volver
                  Provider.of<CourseService>(context, listen: false).getCourses();
                });
              },
            ),
        ],
      ),
      body: isInstructor
          ? _buildInstructorView(courseService)
          : _buildStudentView(courseService, context),
    );
  }

  Widget _buildInstructorView(CourseService courseService) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formulario para añadir/editar cursos
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Editar Curso' : 'Añadir Nuevo Curso',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Curso',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre del curso';
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
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Código del Curso',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el código del curso';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Fecha de inicio'),
                            subtitle: Text(_startDate == null
                                ? 'No seleccionada'
                                : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _startDate = picked);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Fecha de fin'),
                            subtitle: Text(_endDate == null
                                ? 'No seleccionada'
                                : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                            onTap: () async {
                              if (_startDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Primero seleccione la fecha de inicio'),
                                  ),
                                );
                                return;
                              }
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? _startDate!.add(const Duration(days: 1)),
                                firstDate: _startDate!,
                                lastDate: _startDate!.add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _endDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_isEditing)
                          TextButton(
                            onPressed: _resetForm,
                            child: const Text('Cancelar'),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveCourse,
                          child: Text(_isEditing ? 'Actualizar' : 'Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Lista de Cursos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: courseService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : courseService.courses.isEmpty
                    ? const Center(child: Text('No hay cursos disponibles'))
                    : ListView.builder(
                        itemCount: courseService.courses.length,
                        itemBuilder: (context, index) {
                          final course = courseService.courses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(course['name']),
                              subtitle: Text(course['code'] ?? 'Sin código'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editCourse(course),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Confirmar eliminación'),
                                          content: const Text('¿Está seguro de que desea eliminar este curso?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                                _deleteCourse(course['_id']);
                                              },
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentView(CourseService courseService, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Cursos Inscritos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: courseService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : courseService.courses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No estás inscrito en ningún curso'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AvailableCoursesPage()),
                                ).then((_) {
                                  // Recargar los cursos al volver
                                  Provider.of<CourseService>(context, listen: false).getCourses();
                                });
                              },
                              child: const Text('Inscribirse a cursos'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: courseService.courses.length,
                        itemBuilder: (context, index) {
                          final course = courseService.courses[index];
                          final instructorName = course['instructor'] != null
                              ? '${course['instructor']['name']} ${course['instructor']['lastName']}'
                              : 'Instructor no asignado';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['name'],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Código: ${course['code']}'),
                                  const SizedBox(height: 4),
                                  Text('Instructor: $instructorName'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fecha de inicio: ${DateTime.parse(course['startDate']).day}/${DateTime.parse(course['startDate']).month}/${DateTime.parse(course['startDate']).year}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fecha de finalización: ${DateTime.parse(course['endDate']).day}/${DateTime.parse(course['endDate']).month}/${DateTime.parse(course['endDate']).year}',
                                  ),
                                  if (course['description'] != null && course['description'].isNotEmpty) ...[  
                                    const SizedBox(height: 8),
                                    Text('Descripción: ${course['description']}'),
                                  ],
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        // Mostrar diálogo de confirmación
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Confirmar cancelación'),
                                            content: const Text('¿Estás seguro de que deseas cancelar tu inscripción a este curso?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                child: const Text('No'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                child: const Text('Sí'),
                                              ),
                                            ],
                                          ),
                                        );
                                        
                                        if (confirm == true) {
                                          final courseService = Provider.of<CourseService>(context, listen: false);
                                          final result = await courseService.unenrollCourse(course['_id']);
                                          
                                          if (!mounted) return;
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(result['message']),
                                              backgroundColor: result['success'] ? Colors.green : Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Cancelar inscripción'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}