// Basic Flutter widget test for Real Reader app.

import 'package:flutter_test/flutter_test.dart';

import 'package:real_reader/main.dart';
import 'package:real_reader/data/datasources/local/settings_local_datasource.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      RealReaderApp(settingsDatasource: SettingsLocalDatasource()),
    );

    // Verify the app builds
    expect(find.text('REAL READER'), findsOneWidget);
  });
}
