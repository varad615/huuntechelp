import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For setting the status bar color
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hunttechelp/pages/chat.dart';
import 'package:hunttechelp/pages/player.dart';
import 'package:hunttechelp/pages/profile.dart';
import 'package:http/http.dart' as http;
import 'package:hunttechelp/pages/updates.dart';
import 'dart:convert';
import 'package:hunttechelp/pages/youtube.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref(); // Realtime database reference

  User? _currentUser;
  String? _userName;
  Map<String, dynamic>? _videoData; // To store video details
  final String _apiKey =
      'AIzaSyAjCLRtoyb-DXSDduFnEYfKygQOSyvHlDo'; // Your API Key
  String _videoId = ''; // To store fetched video ID from Firebase
  int _unseenAdminMessagesCount = 0; // To store unseen admin messages count
  String? _currentUserId; // To store current user ID

  @override
  void initState() {
    super.initState();
    _getCurrentUserInfo();
    _fetchVideoIdFromDB(); // Fetch video ID from Firebase Realtime Database
    _fetchUnseenMessagesCount(); // Fetch unseen messages count on init
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUnseenMessagesCount(); // Fetch unseen messages count whenever the page loads
  }

  Future<void> _getCurrentUserInfo() async {
    _currentUser = _auth.currentUser;

    if (_currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'];
          _currentUserId = _currentUser!.uid; // Store current user ID
        });
      }
    }
  }

  // Fetch video ID from Firebase Realtime Database
  Future<void> _fetchVideoIdFromDB() async {
    DatabaseReference videoRef = _dbRef.child('setting/videoid');

    videoRef.once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          _videoId = event.snapshot.value.toString(); // Store fetched video ID
        });
        _fetchVideoById(
            _videoId); // Fetch video details using the fetched video ID
      } else {
        print('No video ID found in the database.');
      }
    });
  }

  Future<void> _fetchVideoById(String videoId) async {
    String url =
        'https://www.googleapis.com/youtube/v3/videos?id=$videoId&part=snippet&key=$_apiKey';

    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        _videoData = data['items'][0]['snippet']; // Store video details
      });
    } else {
      print('Error fetching video: ${response.statusCode}');
    }
  }

  Future<void> _fetchUnseenMessagesCount() async {
    String currentUserId = _currentUser!.uid; // Get the current user's UID
    DatabaseReference messagesRef = _dbRef.child(
        'chats/messages/$currentUserId/messages'); // Reference to the user's messages

    messagesRef.once().then((DatabaseEvent event) {
      final data = event.snapshot.value;

      if (data != null) {
        Map<dynamic, dynamic> messages = data as Map<dynamic, dynamic>;
        int unseenAdminCount = 0; // Initialize a counter

        messages.forEach((messageId, message) {
          if (message['userType'] == 'admin' && message['status'] == 'unseen') {
            unseenAdminCount++; // Increment the counter
          }
        });

        setState(() {
          _unseenAdminMessagesCount =
              unseenAdminCount; // Update the UI with the new count
        });

        print('Number of unseen messages from admin: $unseenAdminCount');
      } else {
        print('No messages found for user ID: $currentUserId');
      }
    }).catchError((error) {
      print('Failed to fetch chats/messages: $error');
    });
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-width container with background color and centered text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              decoration: const BoxDecoration(
                color: Color(0xFF51011A), // Set background color
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.0),
                  bottomRight: Radius.circular(8.0),
                ),
              ),
              child: Center(
                child: _userName == null
                    ? const CircularProgressIndicator()
                    : RichText(
                        textAlign: TextAlign.center, // Center align text
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 24, // Set smaller font size
                            color: Colors.white, // White text color
                          ),
                          children: [
                            const TextSpan(
                              text: 'Welcome\n',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: _userName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 28, // Slightly smaller font size
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // Prevent GridView from scrolling
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15.0,
                          mainAxisSpacing: 15.0,
                        ),
                        children: [
                          _buildCard(
                            icon: Icons.chat,
                            label: _unseenAdminMessagesCount > 0
                                ? 'Chat ($_unseenAdminMessagesCount)'
                                : 'Chat',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChatPage()),
                              );
                            },
                          ),
                          _buildCard(
                            icon: Icons.smart_display,
                            label: 'Video Tutorial',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => YouTubePage()),
                              );
                            },
                          ),
                          _buildCard(
                            icon: Icons.account_circle,
                            label: 'Account',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ProfileScreen()),
                              );
                            },
                          ),
                          _buildCard(
                            icon: Icons.update, // Changed icon to Updates
                            label: 'Updates', // Changed label to Updates
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const UpdatesPage()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_videoData != null) ...[
                        const Text(
                          'Video of the Day',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildVideoCard(), // Only display the video card when _videoData is available
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 0, // Removed shadow
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: const Color(0xFF51011A), // Set border color same as theme
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: const Color(0xFF51011A), // Set icon color same as theme
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF51011A), // Set text color same as theme
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(
              videoId: _videoId, // Pass the videoId
              videoTitle: _videoData!['title'], // Pass the video title
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 2,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                _videoData!['thumbnails']['high']['url'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _videoData!['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
