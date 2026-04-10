import 'package:flutter_test/flutter_test.dart';
import 'package:real_reader/data/models/article_model.dart';

void main() {
  final now = DateTime(2024, 1, 1, 12, 0, 0);
  final publishedAt = DateTime(2024, 1, 1, 10, 0, 0);
  final testMap = {
    'id': 'article-1',
    'feed_id': 'feed-1',
    'title': 'Test Article',
    'link': 'https://example.com/article',
    'description': 'A test article description with some words',
    'content': 'Full article content with many more words here',
    'author': 'John Doe',
    'image_url': 'https://example.com/image.jpg',
    'published_at': publishedAt.toIso8601String(),
    'is_read': 0,
    'is_favorite': 1,
    'read_progress': 0.5,
    'is_deleted': 0,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  group('ArticleModel', () {
    test('fromMap creates correct instance', () {
      final article = ArticleModel.fromMap(testMap);
      expect(article.id, 'article-1');
      expect(article.feedId, 'feed-1');
      expect(article.title, 'Test Article');
      expect(article.link, 'https://example.com/article');
      expect(article.description, 'A test article description with some words');
      expect(article.content, 'Full article content with many more words here');
      expect(article.author, 'John Doe');
      expect(article.imageUrl, 'https://example.com/image.jpg');
      expect(article.publishedAt, publishedAt);
      expect(article.isRead, false);
      expect(article.isFavorite, true);
      expect(article.readProgress, 0.5);
      expect(article.isDeleted, false);
      expect(article.createdAt, now);
      expect(article.updatedAt, now);
    });

    test('toMap produces correct map', () {
      final article = ArticleModel.fromMap(testMap);
      final map = article.toMap();
      expect(map['id'], 'article-1');
      expect(map['feed_id'], 'feed-1');
      expect(map['title'], 'Test Article');
      expect(map['link'], 'https://example.com/article');
      expect(map['is_read'], 0);
      expect(map['is_favorite'], 1);
      expect(map['read_progress'], 0.5);
    });

    test('fromMap -> toMap roundtrip preserves data', () {
      final original = ArticleModel.fromMap(testMap);
      final roundtrip = ArticleModel.fromMap(original.toMap());
      expect(roundtrip, original);
    });

    test('toMap -> fromMap roundtrip preserves data', () {
      final article = ArticleModel.fromMap(testMap);
      final map = article.toMap();
      final roundtrip = ArticleModel.fromMap(map);
      expect(roundtrip, article);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = ArticleModel.fromMap(testMap);
      final updated = original.copyWith(
        title: 'Updated Title',
        isRead: true,
      );
      expect(updated.title, 'Updated Title');
      expect(updated.isRead, true);
      expect(updated.id, original.id);
      expect(updated.link, original.link);
    });

    test('Equatable props are correct', () {
      final article1 = ArticleModel.fromMap(testMap);
      final article2 = ArticleModel.fromMap(testMap);
      expect(article1, article2);
      expect(article1.props.length, 15);
    });

    test('readingTimeMinutes calculates correctly', () {
      final article = ArticleModel.fromMap(testMap);
      // description: "A test article description with some words" (8 words)
      // content: "Full article content with many more words here" (9 words)
      // total: 17 words / 200 = 0.085 -> ceil = 1 -> clamp(1, 999) = 1
      expect(article.readingTimeMinutes, 1);
    });

    test('readingTimeMinutes with empty content returns 1', () {
      final mapNoContent = Map<String, dynamic>.from(testMap);
      mapNoContent['description'] = 'word ' * 500; // 500 words
      mapNoContent['content'] = null;
      final article = ArticleModel.fromMap(mapNoContent);
      // 500 words / 200 = 2.5 -> ceil = 3
      expect(article.readingTimeMinutes, 3);
    });

    test('readingTimeMinutes clamps to max 999', () {
      final mapLong = Map<String, dynamic>.from(testMap);
      mapLong['description'] = 'word ' * 200000; // large number of words
      mapLong['content'] = null;
      final article = ArticleModel.fromMap(mapLong);
      expect(article.readingTimeMinutes, 999);
    });

    test('optional fields can be null', () {
      final mapMinimal = {
        'id': 'article-1',
        'feed_id': 'feed-1',
        'title': 'Test Article',
        'link': 'https://example.com/article',
        'is_read': 0,
        'is_favorite': 0,
        'read_progress': 0.0,
        'is_deleted': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final article = ArticleModel.fromMap(mapMinimal);
      expect(article.description, null);
      expect(article.content, null);
      expect(article.author, null);
      expect(article.imageUrl, null);
      expect(article.publishedAt, null);
    });

    test('publishedAt can be null', () {
      final mapNoPubDate = Map<String, dynamic>.from(testMap);
      mapNoPubDate['published_at'] = null;
      final article = ArticleModel.fromMap(mapNoPubDate);
      expect(article.publishedAt, null);
    });

    test('isRead maps from int 1 correctly', () {
      final mapRead = Map<String, dynamic>.from(testMap);
      mapRead['is_read'] = 1;
      final article = ArticleModel.fromMap(mapRead);
      expect(article.isRead, true);
    });
  });
}
