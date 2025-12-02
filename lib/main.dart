// lib/main.dart
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
      theme: ThemeData(primarySwatch: Colors.green),
      // This "StreamBuilder" listens to login state automatically
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // User is Logged In -> Show Home (We will build this next)
            return const HomeScreen(); 
          }
          // User is Logged Out -> Show Login
          return const LoginScreen();
        },
      ),
    );
  }
}

// Temporary Placeholder until we build the real Home Screen in the next step
class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome! You are logged in."),
            ElevatedButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text("Logout"),
            )
          ],
        ),
      ),
    );
  }
}