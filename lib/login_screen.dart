// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // 1. Logic to Sign Up or Log In
  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // REQUIREMENT CHECK: Must be AUI Email
    if (!email.endsWith('@aui.ma')) {
      _showError("Only @aui.ma emails are allowed.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Try to Log In
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
    } on FirebaseAuthException catch (e) {
      // If user not found, try to Sign Up (Create Account)
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        await _signUp(email, password);
      } else {
        _showError(e.message ?? "Error logging in");
      }
    }
    setState(() => _isLoading = false);
  }

  // 2. Logic to Create Account & Database Entry
  Future<void> _signUp(String email, String password) async {
    try {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create the User Document in Firestore with 50 Points
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'balance': 50, // Starting Reward Points
        'major': 'General', // Default
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GoInfo Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "AUI Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _handleAuth,
                  child: const Text("Login / Sign Up"),
                ),
            const SizedBox(height: 10),
            const Text(
              "Note: If account doesn't exist, we will create one.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}