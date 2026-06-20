import 'package:sqflite/sqflite.dart';
import '../../models/article_model.dart';
import 'database_helper.dart';

class ArticleLocalDatasource {
  Future<Database> get _db => DatabaseHelper.database;

  String? _userId;

  void setUserId(String? userId) {
    _userId = userId;
  }

  Future<List<ArticleModel>> getArticlesByFeed(String feedId) async {
    final db = await _db;
    final maps = await db.query(
      'articles',
      where: 'feed_id = ? AND is_deleted = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? [feedId, 0, _userId!] : [feedId, 0],
      orderBy: 'published_at DESC',
    );
    return maps.map((m) => ArticleModel.fromMap(m)).toList();
  }

  Future<List<ArticleModel>> getArticlesByCategory(String categoryId) async {
    final db = await _db;
    final userIdArg = _userId != null ? "AND articles.user_id = ?" : "";
    final args = _userId != null ? [categoryId, 0, 0, _userId!] : [categoryId, 0, 0];
    final maps = await db.rawQuery('''
      SELECT articles.* FROM articles
      INNER JOIN feeds ON articles.feed_id = feeds.id
      WHERE feeds.category_id = ? AND articles.is_deleted = ? AND feeds.is_deleted = ? $userIdArg
      ORDER BY articles.published_at DESC
    ''', args);
    return maps.map((m) => ArticleModel.fromMap(m)).toList();
  }

  Future<List<ArticleModel>> getAllArticles() async {
    final db = await _db;
    final maps = await db.query(
      'articles',
      where: 'is_deleted = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? [0, _userId!] : [0],
      orderBy: 'published_at DESC',
    );
    return maps.map((m) => ArticleModel.fromMap(m)).toList();
  }

  Future<ArticleModel?> getArticleById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'articles',
      where: 'id = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? [id, _userId!] : [id],
    );
    if (maps.isEmpty) return null;
    return ArticleModel.fromMap(maps.first);
  }

  Future<List<ArticleModel>> getFavoriteArticles() async {
    final db = await _db;
    final maps = await db.query(
      'articles',
      where: 'is_favorite = ? AND is_deleted = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? [1, 0, _userId!] : [1, 0],
      orderBy: 'published_at DESC',
    );
    return maps.map((m) => ArticleModel.fromMap(m)).toList();
  }

  Future<List<ArticleModel>> searchArticles(String query) async {
    final db = await _db;
    final maps = await db.query(
      'articles',
      where: '(title LIKE ? OR description LIKE ? OR content LIKE ?) AND is_deleted = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? ['%$query%', '%$query%', '%$query%', 0, _userId!] : ['%$query%', '%$query%', '%$query%', 0],
      orderBy: 'published_at DESC',
    );
    return maps.map((m) => ArticleModel.fromMap(m)).toList();
  }

  Future<void> insertArticle(ArticleModel article) async {
    final db = await _db;
    await db.insert(
      'articles',
      article.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertArticles(List<ArticleModel> articles) async {
    final db = await _db;
    final batch = db.batch();
    for (final article in articles) {
      batch.insert(
        'articles',
        article.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateArticle(ArticleModel article) async {
    final db = await _db;
    await db.update(
      'articles',
      article.toMap(),
      where: 'id = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? [article.id, _userId!] : [article.id],
    );
  }

  Future<void> markRead(String id, bool isRead) async {
    final db = await _db;
    await db.update(
      'articles',
      {
        'is_read': isRead ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? [id, _userId!] : [id],
    );
  }

  Future<void> markFavorite(String id, bool isFavorite) async {
    final db = await _db;
    await db.update(
      'articles',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? [id, _userId!] : [id],
    );
  }

  Future<void> updateReadProgress(String id, double progress) async {
    final db = await _db;
    await db.update(
      'articles',
      {
        'read_progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? [id, _userId!] : [id],
    );
  }

  Future<void> deleteArticle(String id) async {
    final db = await _db;
    await db.update(
      'articles',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? [id, _userId!] : [id],
    );
  }

  Future<void> deleteArticlesByFeed(String feedId) async {
    final db = await _db;
    await db.update(
      'articles',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'feed_id = ?${_userId != null ? " AND user_id = ?" : ""}',
      whereArgs: _userId != null ? [feedId, _userId!] : [feedId],
    );
  }

  Future<int> getUnreadCountByFeed(String feedId) async {
    final db = await _db;
    final userIdClause = _userId != null ? "AND user_id = ?" : "";
    final args = _userId != null ? [feedId, _userId!] : [feedId];
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM articles WHERE feed_id = ? AND is_read = 0 AND is_deleted = 0 $userIdClause',
      args,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalUnreadCount() async {
    final db = await _db;
    final userIdClause = _userId != null ? "AND user_id = ?" : "";
    final args = _userId != null ? [_userId!] : [];
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM articles WHERE is_read = 0 AND is_deleted = 0 $userIdClause',
      args,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
