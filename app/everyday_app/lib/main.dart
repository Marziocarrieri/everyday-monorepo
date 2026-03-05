import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:everyday_app/features/legacy/screens/login2_screen.dart';
import 'package:everyday_app/features/legacy/screens/main_layout.dart';
import 'package:everyday_app/features/legacy/screens/welcome_screen.dart';
import 'services/session_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (url.isEmpty || anonKey.isEmpty) {
    runApp(const SupabaseMissingApp());
    return;
  }

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Everyday',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AppEntryGate(),
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  final SessionInitializer _sessionInitializer = SessionInitializer();
  late final Future<Widget> _initialScreenFuture = _resolveInitialScreen();

  Future<Widget> _resolveInitialScreen() async {
    final state = await _sessionInitializer.initialize();

    if (state == BootstrapState.noSession) {
      return const Login2Screen();
    }

    if (state == BootstrapState.noHousehold) {
      return const WelcomeScreen();
    }

    return const MainLayout();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreenFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data!;
      },
    );
  }
}

class SupabaseMissingApp extends StatelessWidget {
  const SupabaseMissingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Supabase config missing',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}