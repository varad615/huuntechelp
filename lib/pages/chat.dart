import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('chats/messages');
  final DatabaseReference _phoneRef =
      FirebaseDatabase.instance.ref('setting'); // Reference for phone details
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _uid;
  String _username = ''; // Initialize with default value
  String _userType = ''; // Initialize with default value
  String _phoneNumber = ''; // Initialize phone number
  bool _isLoading = true; // Loading state
  bool _isButtonEnabled = false; // Button state
  final ScrollController _scrollController =
      ScrollController(); // Scroll controller for the ListView

  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUser?.uid ?? '';
    _fetchUserInfo(); // Fetch user info once during initialization
    _fetchPhoneDetails(); // Fetch phone number and button state
  }

  // Fetch username and userType from Firestore
  Future<void> _fetchUserInfo() async {
    if (_uid.isNotEmpty) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_uid).get();
      if (userDoc.exists) {
        setState(() {
          _username = userDoc['name'];
          _userType = userDoc['userType']; // Fetch userType from Firestore
          _isLoading = false; // Set loading to false after fetching user info
        });
      } else {
        print("User document does not exist.");
        setState(() {
          _isLoading =
              false; // Set loading to false even if user does not exist
        });
      }
    }
  }

  // Fetch phone number and button state from the database
  Future<void> _fetchPhoneDetails() async {
    DatabaseEvent event = await _phoneRef.once(); // Fetch once to get the data

    if (event.snapshot.exists) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      setState(() {
        _phoneNumber = data['phoneNumber']; // Fetch phone number
        _isButtonEnabled = data['available']; // Fetch button state
      });
    } else {
      print("Phone details not found.");
    }
  }

  // Function to send a message
  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      // Check if the username and userType are set, and create if necessary
      await _checkAndSetUserDetails();

      String messageId = DateTime.now()
          .millisecondsSinceEpoch
          .toString(); // Unique ID for the message
      String timestamp =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Create message data
      Map<String, dynamic> messageData = {
        'text': _messageController.text.trim(),
        'sendOn': timestamp,
        'status': 'unseen',
        'userType': _userType,
      };

      // Store message in the database
      await _dbRef
          .child(_uid)
          .child('messages')
          .child(messageId)
          .set(messageData);

      // Clear the message input field
      _messageController.clear();

      // Scroll to the bottom of the list
      _scrollToBottom();
    }
  }

  // Check if username and userType are already set, and set them if not
  Future<void> _checkAndSetUserDetails() async {
    // Check if the user details already exist in the database
    DatabaseEvent event =
        await _dbRef.child(_uid).once(); // Fetch once to get the data

    if (!event.snapshot.exists) {
      // Only set username and userType if they don't exist
      await _dbRef.child(_uid).child('username').set(_username);
      await _dbRef.child(_uid).child('userType').set(_userType);
    }
  }

  // Function to retrieve messages
  Stream<DatabaseEvent> _getMessages() {
    return _dbRef.child(_uid).child('messages').onValue;
  }

  // Function to make a phone call
  void _makeCall() async {
    if (_isButtonEnabled) {
      final Uri url = Uri(scheme: 'tel', path: _phoneNumber);

      if (await canLaunch(url.toString())) {
        await launch(url.toString());
      } else {
        print('Could not launch $url');
      }
    } else {
      // Show Snackbar if button is disabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User is offline. Will be available soon.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Scroll to the bottom of the list
  void _scrollToBottom() {
    // Check if the controller has any listeners and scroll to the end
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8.0),
            bottomRight: Radius.circular(8.0),
          ),
          child: AppBar(
            backgroundColor: const Color(0xFF51011A), // Set the AppBar color
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white), // White back arrow
              onPressed: () => Navigator.pop(context), // Go back on press
            ),
            title: const Text(
              'Chat',
              style: TextStyle(color: Colors.white), // Set text color to white
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white, // Background color for the button
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.call,
                    color: _isButtonEnabled
                        ? Colors.black
                        : Colors
                            .grey, // Change icon color based on button state
                  ),
                  onPressed: _makeCall, // Call function when pressed
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading // Show loader if loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _getMessages(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error fetching messages'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data?.snapshot.value
                              as Map<dynamic, dynamic>? ??
                          {};
                      List<Map<String, dynamic>> messageList = [];

                      // Prepare a list of messages with keys for sorting
                      messages.forEach((messageId, messageData) {
                        messageList.add({
                          'id': messageId,
                          'text': messageData['text'],
                          'sendOn': messageData['sendOn'],
                          'status': messageData['status'],
                          'userType': messageData['userType'],
                        });

                        if (messageData['userType'] == 'admin' &&
                            messageData['status'] == 'unseen') {
                          _dbRef
                              .child(_uid)
                              .child('messages')
                              .child(messageId)
                              .update({'status': 'seen'});
                        }
                      });

                      // Sort messages by sendOn timestamp
                      messageList.sort((a, b) => DateTime.parse(a['sendOn'])
                          .compareTo(DateTime.parse(b['sendOn'])));

                      List<Widget> messageWidgets =
                          messageList.map((messageData) {
                        bool isMe = messageData['userType'] ==
                            _userType; // Determine if the message is from the user

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft, // Align based on userType
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF3045D3)
                                  : Colors.grey[
                                      300], // Background color based on sender
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  messageData['text'],
                                  style: TextStyle(
                                      color:
                                          isMe ? Colors.white : Colors.black),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  messageData['sendOn'],
                                  style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList();

                      // Scroll to the bottom whenever messages are updated
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView(
                        controller:
                            _scrollController, // Attach the scroll controller
                        children: messageWidgets,
                      );
                    },
                  ),
                ),
                Container(
                  color: const Color(
                      0xFF51011A), // Background color for input area
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.white54),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send,
                              color:
                                  Colors.white), // Change icon color to white
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
