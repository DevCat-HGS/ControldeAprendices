import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:untitled1/services/grade_service.dart';
import 'package:untitled1/services/course_service.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _courses = [];
  String _selectedFilter = 'Todos';
  List<String> _filterOptions = ['Todos'];
  bool _isLoading = true;
  
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
    
    // Cargar calificaciones
    final gradeService = Provider.of<GradeService>(context, listen: false);
    final grades = await gradeService.getStudentGrades();
    
    // Crear opciones de filtro basadas en los cursos disponibles
    final filterOptions = ['Todos'];
    for (var course in courses) {
      filterOptions.add(course['name']);
    }
    
    setState(() {
      _courses = courses;
      _grades = grades;
      _filterOptions = filterOptions;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredGrades {
    if (_selectedFilter == 'Todos') {
      return _grades;
    } else {
      return _grades.where((grade) => 
        grade['course'] != null && 
        grade['course']['name'] == _selectedFilter
      ).toList();
    }
  }

  // Calcular promedio de calificaciones
  double get _averageScore {
    if (_filteredGrades.isEmpty) return 0;
    final total = _filteredGrades.fold<double>(
        0, (sum, grade) => sum + (grade['score'] / grade['evaluation']['maxScore']) * 100);
    return total / _filteredGrades.length;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mis Calificaciones',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Filtro por curso
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por curso',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  value: _selectedFilter,
                  items: _filterOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFilter = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Promedio de calificaciones
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Promedio:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_averageScore.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getColorForScore(_averageScore),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Lista de calificaciones
                Expanded(
                  child: _filteredGrades.isEmpty
                      ? const Center(child: Text('No hay calificaciones disponibles'))
                      : ListView.builder(
                          itemCount: _filteredGrades.length,
                          itemBuilder: (context, index) {
                            final grade = _filteredGrades[index];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getColorForScore((grade['score'] / grade['evaluation']['maxScore']) * 100),
                                  child: Text(
                                    '${(grade['score'] / grade['evaluation']['maxScore'] * 100).round()}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(grade['evaluation']['name']),
                                subtitle: Text(
                                  '${grade['course']['name']} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(grade['evaluation']['dueDate']))}',
                                ),
                                trailing: Text(
                                  '${grade['score']}/${grade['evaluation']['maxScore']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onTap: () {
                                  // Mostrar detalles de la calificación
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(grade['evaluation']['name']),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Descripción: ${grade['evaluation']['description']}'),
                                          const SizedBox(height: 8),
                                          Text('Curso: ${grade['course']['name']}'),
                                          const SizedBox(height: 8),
                                          Text('Fecha de entrega: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(grade['evaluation']['dueDate']))}'),
                                          const SizedBox(height: 8),
                                          Text('Calificación: ${grade['score']}/${grade['evaluation']['maxScore']} (${(grade['score'] / grade['evaluation']['maxScore'] * 100).round()}%)'),
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
                                },
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }

  Color _getColorForScore(double score) {
    if (score >= 90) {
      return Colors.green;
    } else if (score >= 80) {
      return Colors.blue;
    } else if (score >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}