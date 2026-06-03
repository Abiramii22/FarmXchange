import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'services/firebase_service.dart';

import 'data/app_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(initialization: _initializeApp()));
}

Future<void> _initializeApp() async {
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

  /*Future.microtask(() async {
    try {
      await FirebaseService.seedAgentsFromLocalProducts();
    } catch (_) {
      // Background seed must never block app startup.
    }
  });*/
}

class MyApp extends StatelessWidget {
  final Future<void>? initialization;

  const MyApp({super.key, this.initialization});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmXchange',
      builder: (context, child) => FarmTextFix(child: child),
      home: initialization == null
          ? const LoginScreen()
          : FutureBuilder<void>(
              future: initialization,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _StartupScreen();
                }
                if (snapshot.hasError) {
                  return _StartupError(message: snapshot.error.toString());
                }
                return const LoginScreen();
              },
            ),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(image: AssetImage('assets/logo.png'), height: 92),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  final String message;

  const _StartupError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'App start failed: $message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
class FarmTextFix extends StatelessWidget {
  final Widget? child;

  const FarmTextFix({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return _TextFixScope(child: child ?? const SizedBox());
  }
}

class _TextFixScope extends StatelessWidget {
  final Widget child;

  const _TextFixScope({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class FarmText extends Text {
  FarmText(
    String data, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  }) : super(AppStore.fixText(data));
}
