import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled1/services/auth_service.dart';
import 'package:untitled1/services/user_service.dart';
import 'package:untitled1/screens/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _documentNumberController = TextEditingController();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final userData = await userService.getUserProfile();

    if (userData != null) {
      setState(() {
        _userData = userData;
        _firstNameController.text = userData['firstName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _documentNumberController.text = userData['documentNumber'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final userService = Provider.of<UserService>(context, listen: false);
      final success = await userService.updateUserProfile({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'documentNumber': _documentNumberController.text,
      });

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el perfil')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isInstructor = authService.userRole == 'instructor';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi Perfil',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                // Información del usuario
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isEditing
                        ? _buildEditForm()
                        : _buildProfileInfo(isInstructor),
                  ),
                ),
                const SizedBox(height: 16),
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isEditing) ...[                      
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar Perfil'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await authService.logout();
                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar Sesión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else ...[                      
                      ElevatedButton.icon(
                        onPressed: _updateProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            // Restaurar valores originales
                            if (_userData != null) {
                              _firstNameController.text = _userData!['firstName'] ?? '';
                              _lastNameController.text = _userData!['lastName'] ?? '';
                              _emailController.text = _userData!['email'] ?? '';
                              _documentNumberController.text = _userData!['documentNumber'] ?? '';
                            }
                          });
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancelar'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildProfileInfo(bool isInstructor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.person, color: Colors.blue, size: 30),
          title: const Text('Nombre Completo'),
          subtitle: Text(
              '${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? ''}'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.email, color: Colors.blue, size: 30),
          title: const Text('Correo Electrónico'),
          subtitle: Text(_userData?['email'] ?? ''),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.badge, color: Colors.blue, size: 30),
          title: const Text('Número de Documento'),
          subtitle: Text(_userData?['documentNumber'] ?? ''),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.school, color: Colors.blue, size: 30),
          title: const Text('Rol'),
          subtitle: Text(isInstructor ? 'Instructor' : 'Aprendiz'),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Apellido',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu apellido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo electrónico';
              }
              if (!value.contains('@')) {
                return 'Por favor ingresa un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _documentNumberController,
            decoration: const InputDecoration(
              labelText: 'Número de Documento',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu número de documento';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}