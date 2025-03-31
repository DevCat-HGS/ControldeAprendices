import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  Map<String, dynamic> _summary = {};
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _documentController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _documentController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  void _initializeControllers(Map<String, dynamic> userProfile) {
    _nameController.text = userProfile['name'] ?? '';
    _lastNameController.text = userProfile['lastName'] ?? '';
    _emailController.text = userProfile['email'] ?? '';
    _documentController.text = userProfile['documentNumber'] ?? '';
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);

    await profileService.getUserProfile(authService.userId!);

    if (authService.userRole == 'aprendiz') {
      final summaryResult = await profileService.getStudentSummary(authService.userId!);
      if (summaryResult['success']) {
        setState(() {
          _summary = summaryResult['summary'];
        });
      }
    }

    setState(() => _isLoading = false);
  }

  Widget _buildStudentSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen Académico',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Promedio General'),
              subtitle: Text(_summary['averageGrade']?.toString() ?? 'N/A'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Asistencia General'),
              subtitle: Text('${_summary['attendancePercentage']?.toString() ?? 'N/A'}%'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Evaluaciones Completadas'),
              subtitle: Text(_summary['completedEvaluations']?.toString() ?? '0'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);

    final updatedProfile = {
      'name': _nameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'documentNumber': _documentController.text,
    };

    final result = await profileService.updateUserProfile(
      authService.userId!,
      updatedProfile,
    );

    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );

    if (result['success']) {
      await _loadUserProfile();
    }
  }

  Widget _buildProfileInfo(Map<String, dynamic> userProfile) {
    if (_isEditing) {
      return Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                icon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su nombre';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Apellido',
                icon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su apellido';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                icon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su correo';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _documentController,
              decoration: const InputDecoration(
                labelText: 'Documento',
                icon: Icon(Icons.badge),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su documento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _initializeControllers(userProfile);
                    });
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Información Personal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _initializeControllers(userProfile);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Nombre'),
          subtitle: Text('${userProfile['name'] ?? 'N/A'} ${userProfile['lastName'] ?? 'N/A'}'),
        ),
        ListTile(
          leading: const Icon(Icons.email),
          title: const Text('Correo Electrónico'),
          subtitle: Text(userProfile['email'] ?? 'N/A'),
        ),
        ListTile(
          leading: const Icon(Icons.badge),
          title: const Text('Documento'),
          subtitle: Text(userProfile['documentNumber'] ?? 'N/A'),
        ),
        ListTile(
          leading: const Icon(Icons.work),
          title: const Text('Rol'),
          subtitle: Text(userProfile['role'] ?? 'N/A'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profileService = Provider.of<ProfileService>(context);
    final userProfile = profileService.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildProfileInfo(userProfile),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (authService.userRole == 'aprendiz') _buildStudentSummary(),
                  if (authService.userRole == 'instructor')
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estadísticas de Instructor',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.class_),
                              title: const Text('Cursos Activos'),
                              subtitle: Text(userProfile['activeCourses']?.toString() ?? '0'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.people),
                              title: const Text('Total de Estudiantes'),
                              subtitle: Text(userProfile['totalStudents']?.toString() ?? '0'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.assessment),
                              title: const Text('Evaluaciones Pendientes'),
                              subtitle: Text(userProfile['pendingEvaluations']?.toString() ?? '0'),
                            ),
                            const Text(
                              'Gestión de Cursos',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/courses');
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Administrar Cursos'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}