import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled1/screens/login_page.dart';
import 'package:untitled1/services/auth_service.dart';
import 'package:untitled1/services/course_service.dart';
import 'package:untitled1/services/profile_service.dart';
import 'package:untitled1/services/grades_service.dart';
import 'package:untitled1/services/evaluation_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CourseService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => GradesService()),
        ChangeNotifierProvider(create: (_) => EvaluationService()),
      ],
      child: MaterialApp(
        title: 'SENA App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const LoginPage(),
      ),
    );
  }
}