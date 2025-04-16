import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_DSN_HERE';
      options.debug = true;
      options.diagnosticLevel = SentryLevel.debug;
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.sendDefaultPii = true;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: const HelloWorldApp(),
      ),
    ),
  );
}

class HelloWorldApp extends StatelessWidget {
  const HelloWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Sentry Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // Force an error to test if Sentry logs it
              throw Exception(
                  "👋 This is a test exception from Hello World app.");
            },
            child: const Text('Throw Test Error'),
          ),
        ),
      ),
    );
  }
}
