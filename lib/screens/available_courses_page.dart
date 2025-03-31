import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
//import '../services/auth_service.dart';

class AvailableCoursesPage extends StatefulWidget {
  const AvailableCoursesPage({Key? key}) : super(key: key);

  @override
  _AvailableCoursesPageState createState() => _AvailableCoursesPageState();
}

class _AvailableCoursesPageState extends State<AvailableCoursesPage> {
  List<dynamic> _availableCourses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableCourses();
  }

  Future<void> _loadAvailableCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courseService = Provider.of<CourseService>(context, listen: false);
      final courses = await courseService.getAvailableCourses();
      
      setState(() {
        _availableCourses = courses ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _enrollCourse(String courseId, String courseName) async {
    try {
      final courseService = Provider.of<CourseService>(context, listen: false);
      final result = await courseService.enrollCourse(courseId);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      
      if (result['success']) {
        // Recargar la lista de cursos disponibles
        _loadAvailableCourses();
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos Disponibles'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _availableCourses.isEmpty
                  ? const Center(child: Text('No hay cursos disponibles para inscripción'))
                  : RefreshIndicator(
                      onRefresh: _loadAvailableCourses,
                      child: ListView.builder(
                        itemCount: _availableCourses.length,
                        padding: const EdgeInsets.all(16.0),
                        itemBuilder: (context, index) {
                          final course = _availableCourses[index];
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
                                      onPressed: () => _enrollCourse(course['_id'], course['name']),
                                      child: const Text('Inscribirse'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}