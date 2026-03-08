import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/legacy_app/screens/login2_screen.dart';
import 'package:everyday_app/legacy_app/screens/welcome_screen.dart';
import 'shared/services/session_initializer.dart';

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

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Everyday',
      theme: ThemeData(primarySwatch: Colors.blue),
      onGenerateRoute: AppRouter.onGenerateRoute,
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

    return const _RouteRedirectScreen(routeName: AppRouteNames.roleShell);
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

class _RouteRedirectScreen extends StatefulWidget {
  final String routeName;

  const _RouteRedirectScreen({required this.routeName});

  @override
  State<_RouteRedirectScreen> createState() => _RouteRedirectScreenState();
}

class _RouteRedirectScreenState extends State<_RouteRedirectScreen> {
  bool _didRedirect = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRedirect) return;

    _didRedirect = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(widget.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}