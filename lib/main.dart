import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:hunttechelp/pages/main_page.dart';
import 'util.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://e07448e458268dad33d285f3719b57af@o4509161794961408.ingest.de.sentry.io/4509161796534352';
      options.sendDefaultPii = true;
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runZonedGuarded(
      () async {
        await Firebase.initializeApp(); // Firebase after Sentry init
        runApp(
          SentryWidget(
            child: MyApp(),
          ),
        );
      },
      (error, stackTrace) async {
        // Capture any unhandled errors
        await Sentry.captureException(error, stackTrace: stackTrace);
      },
    ),
  );
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
      home: const MainPage(),
    );
  }
}
