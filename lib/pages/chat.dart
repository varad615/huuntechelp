import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userId = '';
  List<Map<String, dynamic>> _messages = [];

  // Send the message with 'type: user'
  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final messageId =
        _database.child('chat').child('messages').child(_userId).push().key;

    _database
        .child('chat')
        .child('messages')
        .child(_userId)
        .child(messageId!)
        .set({
      'text': text,
      'time': DateTime.now().millisecondsSinceEpoch,
      'type': 'user',
    });

    _controller.clear();
  }

  // Retrieve messages and listen for changes
  void _retrieveMessages() {
    _database
        .child('chat')
        .child('messages')
        .child(_userId)
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
          });
        });

        // Sort the messages by timestamp (ascending order)
        loadedMessages.sort((a, b) => b['time'].compareTo(a[
            'time'])); // Change 'a' and 'b' to 'b' and 'a' to reverse the order

        // Update the state to rebuild the UI with the fetched and sorted messages
        setState(() {
          _messages = loadedMessages;
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
      _retrieveMessages();
    }
  }

  // Format the timestamp to display time in hh:mm format
  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour}:${date.minute}";
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
              'Chat',
              style: TextStyle(color: Colors.white), // White text color
            ),
            iconTheme: IconThemeData(color: Colors.white), // White back button
            actions: [
              // Circular button with call icon
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon:
                        Icon(Icons.call, color: Color(0xFF51011A)), // Call icon
                    onPressed: () {
                      // Action for the button
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
          // Display the messages in a ListView
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
                      color:
                          isUserMessage ? Colors.green[300] : Colors.grey[300],
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

          // Input field and Send button at the bottom
          // Input field and Send button at the bottom
          // Input field and Send button at the bottom
          // Input field and Send button at the bottom
          // Input field and Send button at the bottom
          Padding(
            padding: const EdgeInsets.all(0),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF51011A), // Background color for the entire row
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(8.0)), // Rounded top corners
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                          top: 10,
                          bottom: 8,
                          left: 10), // Add top and bottom margin
                      decoration: BoxDecoration(
                        color:
                            Colors.white, // Maroon background for the text box
                        borderRadius:
                            BorderRadius.circular(8.0), // Rounded corners
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white, // Maroon background for the text box
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(8.0), // Rounded corners
                            borderSide: BorderSide.none, // Remove border line
                          ),
                          hintText: 'Enter message',
                          hintStyle:
                              TextStyle(color: Colors.black), // White hint text
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10), // Add horizontal padding
                        ),
                        style:
                            TextStyle(color: Colors.black), // White text color
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon:
                        Icon(Icons.send, color: Color(0xFFFFFFFF)), // Send icon
                    onPressed: () {
                      _sendMessage(_controller.text);
                    },
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
