// Basic Flutter widget test for Real Reader app.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:real_reader/main.dart';
import 'package:real_reader/data/datasources/local/settings_local_datasource.dart';

void main() {
  // Initialize ffi for sqflite in test environment
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      RealReaderApp(
        settingsDatasource: SettingsLocalDatasource(),
        supabaseUrl: '',
        supabaseAnonKey: '',
        database: null,
      ),
    );

    // Verify the app builds
    expect(find.text('REAL READER'), findsOneWidget);
  });
}
