import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: currentPlatform);
  runApp(const GoInfoApp());
}

class GoInfoApp extends StatelessWidget {
  const GoInfoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoInfo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        useMaterial3: true,


        primaryColor: const Color(0xFF00573F), // AUI Green
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Light Grey
        

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00573F),
          primary: const Color(0xFF00573F),
          secondary: const Color(0xFFFFC72C), // Gold
        ),


        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {

          if (!snapshot.data!.emailVerified) {
             FirebaseAuth.instance.signOut();
             return const LoginScreen(); 
          }
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}