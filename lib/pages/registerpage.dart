import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hunttechelp/pages/home.dart';
import 'package:hunttechelp/pages/loginpage.dart'; // Added login page import

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';

  // Function to register with email and password
  Future<void> _register() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      User? user = userCredential.user;

      // Check if user is not null
      if (user != null) {
        print("User registered successfully: ${user.email}");

        // Store user info in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': _name,
          'email': _email,
          'createdAt': FieldValue.serverTimestamp(),
          'userType': 'User', // Adding userType as "User"
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registered as ${user.email}')),
        );

        // Navigate to HomePage after registration
        print("Navigating to HomePage...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle errors
      print("Error occurred during registration: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      // Catch any other errors
      print("An unexpected error occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Add the logo
                Image.asset(
                  'assets/logo.png', // Path to the logo asset
                  height: 150, // Set height as per your requirement
                ),
                const SizedBox(height: 20),

                // Register Text
                const Text(
                  'Register', // Title text
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF51011A), // Primary color
                  ),
                ),
                const SizedBox(height: 30),

                // Name TextFormField
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter your name', // Placeholder text
                    filled: true,
                    fillColor:
                        Colors.grey[200], // Background color for text field
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none, // No visible border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF51011A), // Border color on focus
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _name = value;
                    });
                  },
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 20),

                // Email TextFormField
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter your email', // Placeholder text
                    filled: true,
                    fillColor:
                        Colors.grey[200], // Background color for text field
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none, // No visible border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF51011A), // Border color on focus
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      _email = value;
                    });
                  },
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your email' : null,
                ),
                const SizedBox(height: 20),

                // Password TextFormField
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter your password', // Placeholder text
                    filled: true,
                    fillColor:
                        Colors.grey[200], // Background color for text field
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none, // No visible border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF51011A), // Border color on focus
                      ),
                    ),
                  ),
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {
                      _password = value;
                    });
                  },
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your password' : null,
                ),
                const SizedBox(height: 20),

                // Register Button
                SizedBox(
                  width: double.infinity, // Full width button
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _register();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF51011A), // Primary color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Rounded button corners
                      ),
                      elevation: 0, // No shadow
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.all(20), // Button padding
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Text button for already having an account
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      color: Color(0xFF51011A), // Primary color for text button
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
