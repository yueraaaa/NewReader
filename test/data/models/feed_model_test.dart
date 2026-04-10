import 'package:flutter_test/flutter_test.dart';
import 'package:real_reader/data/models/feed_model.dart';

void main() {
  final now = DateTime(2024, 1, 1, 12, 0, 0);
  final testMap = {
    'id': 'feed-1',
    'title': 'Test Feed',
    'url': 'https://example.com/feed',
    'description': 'A test feed',
    'icon_url': 'https://example.com/icon.png',
    'category_id': 'cat-1',
    'is_deleted': 0,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  group('FeedModel', () {
    test('fromMap creates correct instance', () {
      final feed = FeedModel.fromMap(testMap);
      expect(feed.id, 'feed-1');
      expect(feed.title, 'Test Feed');
      expect(feed.url, 'https://example.com/feed');
      expect(feed.description, 'A test feed');
      expect(feed.iconUrl, 'https://example.com/icon.png');
      expect(feed.categoryId, 'cat-1');
      expect(feed.isDeleted, false);
      expect(feed.createdAt, now);
      expect(feed.updatedAt, now);
    });

    test('toMap produces correct map', () {
      final feed = FeedModel.fromMap(testMap);
      final map = feed.toMap();
      expect(map['id'], 'feed-1');
      expect(map['title'], 'Test Feed');
      expect(map['url'], 'https://example.com/feed');
      expect(map['description'], 'A test feed');
      expect(map['icon_url'], 'https://example.com/icon.png');
      expect(map['category_id'], 'cat-1');
      expect(map['is_deleted'], 0);
    });

    test('fromMap -> toMap roundtrip preserves data', () {
      final original = FeedModel.fromMap(testMap);
      final roundtrip = FeedModel.fromMap(original.toMap());
      expect(roundtrip, original);
    });

    test('toMap -> fromMap roundtrip preserves data', () {
      final feed = FeedModel.fromMap(testMap);
      final map = feed.toMap();
      final roundtrip = FeedModel.fromMap(map);
      expect(roundtrip, feed);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = FeedModel.fromMap(testMap);
      final updated = original.copyWith(
        title: 'Updated Title',
        url: 'https://updated.com/feed',
      );
      expect(updated.title, 'Updated Title');
      expect(updated.url, 'https://updated.com/feed');
      expect(updated.id, original.id);
      expect(updated.description, original.description);
    });

    test('copyWith with null optional field preserves original (standard Dart copyWith behavior)', () {
      final original = FeedModel.fromMap(testMap);
      // copyWith uses ??, so passing null preserves the original value
      // This is standard Dart copyWith behavior - null means "don't change"
      final updated = original.copyWith(description: null);
      expect(updated.description, original.description);
    });

    test('Equatable props are correct', () {
      final feed1 = FeedModel.fromMap(testMap);
      final feed2 = FeedModel.fromMap(testMap);
      expect(feed1, feed2);
      expect(feed1.props.length, 9);
    });

    test('isDeleted maps from int 1 correctly', () {
      final mapDeleted = Map<String, dynamic>.from(testMap);
      mapDeleted['is_deleted'] = 1;
      final feed = FeedModel.fromMap(mapDeleted);
      expect(feed.isDeleted, true);
    });

    test('optional fields can be null', () {
      final mapMinimal = {
        'id': 'feed-1',
        'title': 'Test Feed',
        'url': 'https://example.com/feed',
        'is_deleted': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final feed = FeedModel.fromMap(mapMinimal);
      expect(feed.description, null);
      expect(feed.iconUrl, null);
      expect(feed.categoryId, null);
    });
  });
}
