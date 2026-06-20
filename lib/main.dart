import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/settings/settings_event.dart';
import 'presentation/blocs/settings/settings_state.dart';
import 'presentation/blocs/feed/feed_bloc.dart';
import 'presentation/blocs/feed/feed_event.dart';
import 'presentation/blocs/article/article_bloc.dart';
import 'presentation/blocs/ai/ai_bloc.dart';
import 'data/datasources/local/database_helper.dart';
import 'data/datasources/local/settings_local_datasource.dart';
import 'data/datasources/local/feed_local_datasource.dart';
import 'data/datasources/local/article_local_datasource.dart';
import 'data/datasources/remote/supabase_datasource.dart';
import 'data/services/sync_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/feed_repository_impl.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final db = await DatabaseHelper.database;

  // Read API keys from database (falls back to environment variables)
  final settingsDatasource = SettingsLocalDatasource();
  final dbSupabaseUrl = await settingsDatasource.getSetting('supabase_url');
  final dbSupabaseAnonKey = await settingsDatasource.getSetting('supabase_anon_key');

  // Use database values if available, otherwise fall back to environment variables
  final supabaseUrl = dbSupabaseUrl?.isNotEmpty == true
      ? dbSupabaseUrl!
      : AppConfig.supabaseUrl;
  final supabaseAnonKey = dbSupabaseAnonKey?.isNotEmpty == true
      ? dbSupabaseAnonKey!
      : AppConfig.supabaseAnonKey;

  // Initialize Supabase if credentials are available
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await supabase.Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(RealReaderApp(
    settingsDatasource: settingsDatasource,
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
    database: db,
  ));
}

class RealReaderApp extends StatelessWidget {
  final SettingsLocalDatasource settingsDatasource;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final dynamic database;

  const RealReaderApp({
    super.key,
    required this.settingsDatasource,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.database,
  });

  @override
  Widget build(BuildContext context) {
    // Create datasources
    final feedLocalDatasource = FeedLocalDatasource();
    final articleDatasource = ArticleLocalDatasource();
    SupabaseDatasource? supabaseDatasource;
    SyncService? syncService;

    // Only create Supabase datasource if credentials are available
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      final supabaseClient = supabase.Supabase.instance.client;
      supabaseDatasource = SupabaseDatasource(supabaseClient);
      syncService = SyncService(supabaseDatasource, database);
    }

    // Create repositories
    final AuthRepository authRepository = AuthRepositoryImpl(supabaseDatasource);
    final feedRepository = FeedRepositoryImpl(
      localDatasource: feedLocalDatasource,
      supabaseDatasource: supabaseDatasource,
      syncService: syncService,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepository)..add(AuthCheckRequested())),
        BlocProvider(create: (_) => SettingsBloc(settingsDatasource: settingsDatasource)..add(LoadSettings())),
        BlocProvider(create: (context) => FeedBloc(
          feedRepository: feedRepository,
          authBloc: context.read<AuthBloc>(),
        )..add(LoadFeeds())),
        BlocProvider(create: (_) => ArticleBloc(
          articleDatasource: articleDatasource,
          supabaseDatasource: supabaseDatasource,
          authBloc: context.read<AuthBloc>(),
        )),
        BlocProvider(create: (_) => AiBloc()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'Real Reader',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
