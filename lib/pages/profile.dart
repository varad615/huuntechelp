import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _name;
  String? _email;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        setState(() {
          _name = snapshot['name'];
          _email = user.email; // Fetch email directly from the user object
        });
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.of(context)
        .pop(); // Navigate back to the login page or previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile',
            style: TextStyle(
                color: Colors.white)), // Set title text color to white
        backgroundColor: Color(0xFF51011A),
        iconTheme: IconThemeData(
            color: Colors.white), // Set the back arrow color to white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${_name ?? 'Loading...'}',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF51011A)), // Set name text color to white
            ),
            SizedBox(height: 16),
            Text(
              'Email: ${_email ?? 'Loading...'}',
              style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF51011A)), // Set email text color to white
            ),
            Spacer(),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout,
                  color: Colors.white), // Set icon color to white
              label: Text('Logout',
                  style: TextStyle(
                      color: Colors.white)), // Set text color to white
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF51011A), // Use your color here
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      12), // Rounded corners for Material 3
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
