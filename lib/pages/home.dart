import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hunttechelp/pages/chat.dart';
import 'package:hunttechelp/pages/profile.dart';
import 'package:hunttechelp/pages/youtube.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _getCurrentUserInfo();
  }

  Future<void> _getCurrentUserInfo() async {
    _currentUser = _auth.currentUser;

    if (_currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'];
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message with user's name
              _userName == null
                  ? CircularProgressIndicator()
                  : RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 36,
                            color:
                                Colors.black), // Refined size for modern look
                        children: [
                          TextSpan(
                            text: 'Welcome\n', // No comma, name in next line
                            style: TextStyle(
                              color: Color(0xFF51011A), // Maroon accent
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: _userName!,
                            style: TextStyle(
                              color: Color(0xFF51011A), // Maroon color for name
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                            ),
                          ),
                        ],
                      ),
                    ),

              SizedBox(height: 20), // Balanced space

              // Grid of 2x2 cards
              Expanded(
                child: GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15.0, // Subtle space between cards
                    mainAxisSpacing: 15.0, // Subtle space between cards
                  ),
                  children: [
                    // Box 1: Chat
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Chat()),
                        );
                      },
                      child: _buildCard(
                        icon: Icons.chat,
                        label: 'Chat',
                        bgColor: Colors.white, // Clean background
                        iconColor: Color(0xFF51011A), // Maroon for icons
                        shadowColor:
                            Colors.grey.shade300, // Subtle shadow for depth
                      ),
                    ),
                    // Box 2: YouTube
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => YouTubePage()),
                        );
                      },
                      child: _buildCard(
                        icon: Icons.smart_display,
                        label: 'Video Tutorial',
                        bgColor: Colors.white,
                        iconColor: Color(0xFF51011A),
                        shadowColor: Colors.grey.shade300,
                      ),
                    ),
                    // Box 3: Account
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfileScreen()));
                      },
                      child: _buildCard(
                        icon: Icons.account_circle,
                        label: 'Account',
                        bgColor: Colors.white,
                        iconColor: Color(0xFF51011A),
                        shadowColor: Colors.grey.shade300,
                      ),
                    ),
                    // Box 4: Call
                    _buildCard(
                      icon: Icons.call,
                      label: 'Call',
                      bgColor: Colors.white,
                      iconColor: Color(0xFF51011A),
                      shadowColor: Colors.grey.shade300,
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

  // Helper function to build modern card
  Widget _buildCard({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required Color shadowColor,
  }) {
    return Material(
      elevation: 5, // For the card's floating effect
      borderRadius: BorderRadius.circular(12.0),
      shadowColor: shadowColor,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60, // Slightly smaller for professional balance
              color: iconColor,
            ),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87, // Professional, clean text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
