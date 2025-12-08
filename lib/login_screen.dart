import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- LOGIC: REGISTER ---
  Future<void> _register() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Strict AUI Email Check
    if (!email.endsWith('@aui.ma')) {
      _showError("Access Denied: Please use your @aui.ma email.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 2. Create Account
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Send Verification Email
      await cred.user!.sendEmailVerification();

      // 4. Create Database Entry
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'balance': 50,
        'major': 'General', 
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // ADD THIS: Record the Welcome Bonus
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .collection('transactions')
          .add({
            'amount': 50,
            'description': "Welcome Bonus",
            'timestamp': FieldValue.serverTimestamp(),
          });

      // 5. Alert User and Logout
      await FirebaseAuth.instance.signOut();
      _showSuccess("Account created! We sent a verification link to your email. Please verify before logging in.");
      _tabController.animateTo(0); // Switch to Login tab

    } catch (e) {
      _showError(e.toString());
    }
    setState(() => _isLoading = false);
  }

  // --- LOGIC: LOGIN ---
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 1. Check if Email is Verified
      if (!cred.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        _showError("Email not verified! Please check your inbox.");
        setState(() => _isLoading = false);
        return;
      }
      
      // If verified, Main.dart handles the redirect to Home
    } catch (e) {
      _showError("Login failed. Check your email or password.");
    }
    setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Success"),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00573F), // AUI Green Background
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Logo Area
              const Icon(Icons.school, size: 80, color: Colors.white),
              const SizedBox(height: 10),
              const Text(
                "GoInfo",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text(
                "AUI Community Platform",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 30),

              // The White Card
              Container(
                width: 350,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF00573F),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF00573F),
                      tabs: const [Tab(text: "Login"), Tab(text: "Register")],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "AUI Email", prefixIcon: Icon(Icons.email)),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)),
                      obscureText: true,
                    ),
                    const SizedBox(height: 25),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00573F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                if (_tabController.index == 0) {
                                  _login();
                                } else {
                                  _register();
                                }
                              },
                              child: Text(
                                _tabController.index == 0 ? "LOGIN" : "CREATE ACCOUNT",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}