import 'package:flutter/material.dart';
import 'package:hunttechelp/pages/default_page.dart';
import 'util.dart';
import 'theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, "ABeeZee", "ABeeZee");

    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Health App',
      theme: theme.light(),
      home: DefaultPage(), // This now launches directly with no Firebase
    );
  }
}
