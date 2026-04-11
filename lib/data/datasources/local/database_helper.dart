import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'real_reader.db';
  static const _databaseVersion = 2;

  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        user_id TEXT DEFAULT '',
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE feeds (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        description TEXT,
        icon_url TEXT,
        category_id TEXT REFERENCES categories(id),
        user_id TEXT DEFAULT '',
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE articles (
        id TEXT PRIMARY KEY,
        feed_id TEXT NOT NULL REFERENCES feeds(id),
        title TEXT NOT NULL,
        link TEXT NOT NULL,
        description TEXT,
        content TEXT,
        author TEXT,
        image_url TEXT,
        published_at TEXT,
        is_read INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        read_progress REAL DEFAULT 0,
        user_id TEXT DEFAULT '',
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_metadata (
        table_name TEXT PRIMARY KEY,
        last_synced_at TEXT
      )
    ''');

    // Indexes for performance
    await db.execute(
        'CREATE INDEX idx_articles_feed_id ON articles(feed_id)');
    await db.execute(
        'CREATE INDEX idx_articles_published_at ON articles(published_at)');
    await db.execute(
        'CREATE INDEX idx_feeds_category_id ON feeds(category_id)');
    // Index for user isolation queries
    await db.execute(
        'CREATE INDEX idx_feeds_user_id ON feeds(user_id)');
    await db.execute(
        'CREATE INDEX idx_articles_user_id ON articles(user_id)');
    await db.execute(
        'CREATE INDEX idx_categories_user_id ON categories(user_id)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from v1 to v2: add user_id column
      await db.execute('ALTER TABLE feeds ADD COLUMN user_id TEXT DEFAULT ""');
      await db.execute('ALTER TABLE articles ADD COLUMN user_id TEXT DEFAULT ""');
      await db.execute('ALTER TABLE categories ADD COLUMN user_id TEXT DEFAULT ""');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_feeds_user_id ON feeds(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_articles_user_id ON articles(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id)');
    }
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
