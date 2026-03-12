import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:everyday_app/legacy_app/screens/login2_screen.dart';

void main() {
  testWidgets('Login2Screen shows form fields and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Login2Screen()));

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}

