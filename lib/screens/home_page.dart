import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled1/screens/attendance_page.dart';
import 'package:untitled1/screens/evaluation_page.dart';
import 'package:untitled1/screens/grades_page.dart';
import 'package:untitled1/screens/profile_page.dart';
import 'package:untitled1/services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isInstructor = authService.userRole == 'instructor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SENA App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(isInstructor),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: _buildNavItems(isInstructor),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(bool isInstructor) {
    if (isInstructor) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle),
          label: 'Asistencia',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Evaluaciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Evaluaciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grade),
          label: 'Calificaciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }
  }

  Widget _buildBody(bool isInstructor) {
    if (isInstructor) {
      switch (_selectedIndex) {
        case 0:
          return _buildInstructorHome();
        case 1:
          return const AttendancePage();
        case 2:
          return const EvaluationPage();
        case 3:
          return const ProfilePage();
        default:
          return _buildInstructorHome();
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return _buildStudentHome();
        case 1:
          return const EvaluationPage();
        case 2:
          return const GradesPage();
        case 3:
          return const ProfilePage();
        default:
          return _buildStudentHome();
      }
    }
  }

  Widget _buildInstructorHome() {
    final authService = Provider.of<AuthService>(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido, ${authService.userName ?? "Instructor"}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mis Cursos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 3, // Ejemplo con 3 cursos
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.school, color: Colors.blue),
                    title: Text('Curso ${index + 1}'),
                    subtitle: Text('Código: C00${index + 1}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navegar a detalles del curso
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

  Widget _buildStudentHome() {
    final authService = Provider.of<AuthService>(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido, ${authService.userName ?? "Aprendiz"}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mis Materias',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4, // Ejemplo con 4 materias
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.book, color: Colors.blue),
                    title: Text('Materia ${index + 1}'),
                    subtitle: Text('Instructor: Profesor ${index + 1}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navegar a detalles de la materia
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
}