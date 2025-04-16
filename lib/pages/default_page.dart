import 'package:flutter/material.dart';

class DefaultPage extends StatelessWidget {
  const DefaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Default Page"),
      ),
      body: const Center(
        child: Text(
          "🎯 If you see this, things are working!",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
