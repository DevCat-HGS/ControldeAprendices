import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'attendance_page.dart';
import 'evaluation_page.dart';
import 'course_page.dart';
import 'profile_page.dart';
import 'grades_page.dart';
import 'available_courses_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userRole = authService.userRole;
    final userName = authService.userName ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SENA App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    userRole == 'instructor' ? 'Instructor' : 'Aprendiz',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            if (userRole == 'instructor') ...
            [
              ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('Registrar Asistencia'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AttendancePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.grading),
                title: const Text('Evaluaciones'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EvaluationPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Gestión de Cursos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CoursePage()),
                  );
                },
              ),
            ]
            else ...
            [
              ListTile(
                leading: const Icon(Icons.grading),
                title: const Text('Evaluaciones'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EvaluationPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Mis Cursos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CoursePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('Cursos Disponibles'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AvailableCoursesPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment_turned_in),
                title: const Text('Mis Evaluaciones'),
                onTap: () {
                  Navigator.pop(context);
                  // Navegar a la página de evaluaciones del aprendiz
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.grade),
              title: const Text('Mis Notas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GradesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                // Navegar a la página de configuración
              },
            ),
          ],
        ),
      ),
      body: userRole == 'instructor' ? _buildInstructorView() : _buildApprenticeView(),
    );
  }

  Widget _buildInstructorView() {
    final profileService = Provider.of<ProfileService>(context);
    final userProfile = profileService.userProfile;

    if (profileService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Cursos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCoursesList(userProfile['courses'] ?? []),
          const SizedBox(height: 24),
          const Text(
            'Asistencias Recientes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRecentAttendanceList(userProfile['attendance'] ?? []),
          const SizedBox(height: 24),
          const Text(
            'Evaluaciones Pendientes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Lista de evaluaciones pendientes (simulada)
          _buildPendingEvaluationsList(),
        ],
      ),
    );
  }

  Widget _buildApprenticeView() {
    final profileService = Provider.of<ProfileService>(context);
    final userProfile = profileService.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Materias',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEnrolledCoursesList(userProfile['courses'] ?? []),
          const SizedBox(height: 24),
          const Text(
            'Calificaciones Recientes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRecentGradesList(userProfile['evaluations'] ?? []),
        ],
      ),
    );
  }

  // Widgets para la vista del instructor
  Widget _buildCoursesList(List<dynamic> courses) {

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(course['name'] as String),
            subtitle: Text('Código: ${course['code']} | Estudiantes: ${course['students']}'),
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.school, color: Colors.white),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navegar a los detalles del curso
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentAttendanceList(List<dynamic> attendances) {

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attendances.length,
      itemBuilder: (context, index) {
        final attendance = attendances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(attendance['course'] as String),
            subtitle: Text('Fecha: ${attendance['date']} | Asistencia: ${attendance['attendance']}'),
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white),
            ),
            onTap: () {
              // Navegar a los detalles de la asistencia
            },
          ),
        );
      },
    );
  }

  Widget _buildPendingEvaluationsList() {
    // Datos simulados de evaluaciones pendientes
    final evaluations = [
      {'title': 'Proyecto Final', 'course': 'Desarrollo de Software', 'deadline': '30/05/2023'},
      {'title': 'Examen Parcial', 'course': 'Bases de Datos', 'deadline': '22/05/2023'},
      {'title': 'Taller Práctico', 'course': 'Programación Web', 'deadline': '25/05/2023'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: evaluations.length,
      itemBuilder: (context, index) {
        final evaluation = evaluations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(evaluation['title'] as String),
            subtitle: Text('${evaluation['course']} | Fecha límite: ${evaluation['deadline']}'),
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.assignment, color: Colors.white),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navegar a los detalles de la evaluación
            },
          ),
        );
      },
    );
  }

  // Widgets para la vista del aprendiz
  Widget _buildEnrolledCoursesList(List<dynamic> courses) {

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(course['name'] as String),
            subtitle: Text('Instructor: ${course['instructor']} | Horario: ${course['schedule']}'),
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.book, color: Colors.white),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navegar a los detalles de la materia
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentGradesList(List<dynamic> grades) {

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grades.length,
      itemBuilder: (context, index) {
        final grade = grades[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(grade['title'] as String),
            subtitle: Text('${grade['course']} | Fecha: ${grade['date']}'),
            leading: CircleAvatar(
              backgroundColor: _getGradeColor(grade['grade'] as String),
              child: Text(
                _getGradeValue(grade['grade'] as String),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            trailing: Text(
              grade['grade'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              // Navegar a los detalles de la calificación
            },
          ),
        );
      },
    );
  }

  // Función auxiliar para determinar el color según la calificación
  Color _getGradeColor(String grade) {
    final score = int.parse(grade.split('/')[0]);
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  // Función auxiliar para obtener el valor de la calificación para mostrar en el avatar
  String _getGradeValue(String grade) {
    final score = int.parse(grade.split('/')[0]);
    return (score / 10).floor().toString();
  }
}