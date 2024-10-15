import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(Chat());
}

class Chat extends StatefulWidget {
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final _database = FirebaseDatabase.instance.ref();
  final _firestore = FirebaseFirestore.instance;
  final _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userId = '';
  String _username = ''; // To store fetched username
  List<Map<String, dynamic>> _messages = [];
  bool _isCallEnabled = false; // Initially disabled
  String _phoneNumber = '';

  // Send the message with 'type: user'
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageId = _database.child('chats').child('messages').child(_userId).child(_username).push().key;

    if (messageId != null) {
      // Add message under user's chat node with username
      await _database
          .child('chats')
          .child('messages')
          .child(_userId)
          .child(_username) // Store messages under the username
          .child(messageId)
          .set({
        'text': text,
        'time': DateTime.now().millisecondsSinceEpoch,
        'type': 'user',
        'seen': false, // Add seen status
      });

      _controller.clear();
    }
  }

  // Retrieve messages and listen for changes
  void _retrieveMessages() {
    _database
        .child('chats')
        .child('messages')
        .child(_userId)
        .child(_username) // Listen under the username
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final List<Map<String, dynamic>> loadedMessages = [];

        data.forEach((key, value) {
          final messageData = value as Map<dynamic, dynamic>;
          loadedMessages.add({
            'text': messageData['text'],
            'time': messageData['time'],
            'type': messageData['type'],
            'seen': messageData['seen'],
          });
        });

        // Sort the messages by timestamp (ascending order)
        loadedMessages.sort((a, b) => b['time'].compareTo(a['time']));

        setState(() {
          _messages = loadedMessages;
        });

        // Mark messages as seen
        _markMessagesAsSeen();
      }
    });
  }

  // Fetch phone number and availability from Firebase
  void _fetchPhoneDetails() {
    _database.child('phoneDetails').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          _phoneNumber = data['phoneNumber'] ?? '';
          _isCallEnabled = data['available'] ?? false;
        });
      }
    });
  }

  // Fetch user's username from Firestore
  Future<void> _fetchUsername() async {
    final userDoc = await _firestore.collection('users').doc(_userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      _username = userData['name'] ?? 'Unknown User';

      // Store username in Firebase Realtime Database if not already stored
      await _database
          .child('chats')
          .child('messages')
          .child(_userId)
          .child(_username); // Store under username only once
    }
  }

  // Mark messages as seen when displayed
  void _markMessagesAsSeen() {
    _messages.forEach((message) {
      if (!message['seen']) {
        final messageRef = _database
            .child('chats')
            .child('messages')
            .child(_userId)
            .child(_username)
            .orderByChild('seen')
            .equalTo(false)
            .once()
            .then((snapshot) {
              final updates = Map<String, dynamic>();
              snapshot.snapshot.children.forEach((child) {
                updates['${child.key}/seen'] = true;
              });
              _database.child('chats/messages/$_userId/$_username').update(updates);
            });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });

      // Fetch the username if it's the first time starting the chat
      _database.child('chats/messages').child(_userId).once()
          .then((DatabaseEvent snapshot) {
        if (snapshot.snapshot.value == null) {
          // If no username found, fetch it from Firestore
          _fetchUsername();
        } else {
          // If username exists, retrieve and set it
          setState(() {
            final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
            _username = data.keys.first; // Assuming only one username per user
          });
        }
      });

      _retrieveMessages();
      _fetchPhoneDetails(); // Fetch phone details when the widget initializes
    }
  }

  // Format the timestamp to display date and time
  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy, hh:mm a').format(date);
  }

  // Make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  void createTemporaryNumber() {
    _database.child('phoneDetails').set({
      'phoneNumber': '8691937999',
      'available': true,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Temporary number created with availability')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Custom height
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(8.0), // Rounded corners
          ),
          child: AppBar(
            backgroundColor: Color(0xFF51011A), // Maroon color
            title: Text(
              'Chat with $_username', // Show username in AppBar
              style: TextStyle(color: Colors.white), // White text color
            ),
            iconTheme: IconThemeData(color: Colors.white), // White back button
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      Icons.call,
                      color: _isCallEnabled
                          ? Color(0xFF51011A)
                          : Colors.grey, // Show gray when disabled
                    ),
                    onPressed: _isCallEnabled
                        ? () {
                            _makePhoneCall(_phoneNumber); // Use fetched phone number
                          }
                        : () {
                            // Show snackbar when the button is disabled
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('User is not available. Call after some time.'),
                              ),
                            );
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              reverse: true, // New messages appear at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isUserMessage = message['type'] == 'user';

                return Align(
                  alignment: isUserMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUserMessage ? Colors.green[300] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: isUserMessage
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['text'],
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 5),
                        Text(
                          _formatTimestamp(message['time']),
                          style: TextStyle(color: Colors.black54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createTemporaryNumber, // Create temporary phone number
        child: Icon(Icons.phone),
        backgroundColor: Color(0xFF51011A),
      ),
    );
  }
}
