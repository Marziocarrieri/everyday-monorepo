import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:everyday_app/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows form fields and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}

