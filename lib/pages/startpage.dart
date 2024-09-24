import 'package:flutter/material.dart';

class Startpage extends StatelessWidget {
  const Startpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My App'),
      ),
      body: Center(child: Text("data")),
    );
  }
}
