// Basic Flutter widget test for Real Reader app.

import 'package:flutter_test/flutter_test.dart';

import 'package:real_reader/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RealReaderApp());

    // Verify the app builds
    expect(find.text('REAL READER'), findsOneWidget);
  });
}
