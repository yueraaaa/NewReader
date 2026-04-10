import 'package:flutter_test/flutter_test.dart';
import 'package:real_reader/data/services/opml_service.dart';
import 'package:real_reader/data/models/feed_model.dart';
import 'package:real_reader/data/models/category_model.dart';

void main() {
  late OpmlService opmlService;

  setUp(() {
    opmlService = OpmlService();
  });

  group('OpmlService', () {
    group('exportToOpml', () {
      test('produces valid OPML 2.0 with feeds and categories', () {
        final now = DateTime.now();
        final feeds = [
          FeedModel(
            id: 'feed-1',
            title: 'The Verge',
            url: 'https://www.theverge.com/rss/index.xml',
            description: 'https://www.theverge.com',
            categoryId: 'cat-tech',
            isDeleted: false,
            createdAt: now,
            updatedAt: now,
          ),
          FeedModel(
            id: 'feed-2',
            title: 'Ars Technica',
            url: 'https://feeds.arstechnica.com/arstechnica/index',
            description: 'https://arstechnica.com',
            isDeleted: false,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final categories = [
          CategoryModel(
            id: 'cat-tech',
            name: 'Tech',
            color: '#00497d',
            sortOrder: 0,
            isDeleted: false,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final opml = opmlService.exportToOpml(feeds, categories);

        // Verify OPML structure
        expect(opml, contains('<?xml'));
        expect(opml, contains('<opml version="2.0">'));
        expect(opml, contains('<head>'));
        expect(opml, contains('<title>Real Reader Subscriptions</title>'));
        expect(opml, contains('<body>'));
        expect(opml, contains('</body>'));
        expect(opml, contains('</head>'));
        expect(opml, contains('</opml>'));

        // Verify feed is present
        expect(opml, contains('xmlUrl="https://www.theverge.com/rss/index.xml"'));
        expect(opml, contains('text="The Verge"'));

        // Verify category structure
        expect(opml, contains('<outline text="Tech" title="Tech">'));
      });

      test('excludes deleted feeds and categories', () {
        final now = DateTime.now();
        final feeds = [
          FeedModel(
            id: 'feed-1',
            title: 'Active Feed',
            url: 'https://example.com/feed',
            isDeleted: false,
            createdAt: now,
            updatedAt: now,
          ),
          FeedModel(
            id: 'feed-2',
            title: 'Deleted Feed',
            url: 'https://deleted.com/feed',
            isDeleted: true,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final categories = [
          CategoryModel(
            id: 'cat-1',
            name: 'Active Category',
            color: '#00497d',
            isDeleted: false,
            createdAt: now,
            updatedAt: now,
          ),
          CategoryModel(
            id: 'cat-2',
            name: 'Deleted Category',
            color: '#713700',
            isDeleted: true,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        // Add feed to Active Category
        feeds[0] = feeds[0].copyWith(categoryId: 'cat-1');

        final opml = opmlService.exportToOpml(feeds, categories);

        expect(opml, contains('Active Feed'));
        expect(opml, contains('Active Category'));
        expect(opml, isNot(contains('Deleted Feed')));
        expect(opml, isNot(contains('Deleted Category')));
      });

      test('puts uncategorized feeds at root level', () {
        final now = DateTime.now();
        final feeds = [
          FeedModel(
            id: 'feed-1',
            title: 'Uncategorized Feed',
            url: 'https://example.com/feed',
            categoryId: null,
            isDeleted: false,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final opml = opmlService.exportToOpml(feeds, []);

        // Uncategorized feed should appear directly in body
        expect(opml, contains('text="Uncategorized Feed"'));
        // Should NOT be inside a category outline
        expect(opml, isNot(contains('<outline text="Uncategorized Feed"')));
      });
    });

    group('parseOpml', () {
      test('parses OPML and returns feeds and categories', () {
        const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head>
    <title>Real Reader Subscriptions</title>
    <dateCreated>2024-01-15T10:30:00Z</dateCreated>
  </head>
  <body>
    <outline text="Tech" title="Tech">
      <outline type="rss" text="The Verge" title="The Verge" xmlUrl="https://www.theverge.com/rss/index.xml" htmlUrl="https://www.theverge.com"/>
    </outline>
    <outline type="rss" text="Ars Technica" title="Ars Technica" xmlUrl="https://feeds.arstechnica.com/arstechnica/index" htmlUrl="https://arstechnica.com"/>
  </body>
</opml>''';

        final result = opmlService.parseOpml(opml);

        expect(result.feeds.length, 2);
        expect(result.categories.length, 1);

        // Check feeds
        final theVerge = result.feeds.firstWhere((f) => f.title == 'The Verge');
        expect(theVerge.url, 'https://www.theverge.com/rss/index.xml');
        expect(theVerge.description, 'https://www.theverge.com');
        expect(theVerge.categoryId, isNotNull);

        final ars = result.feeds.firstWhere((f) => f.title == 'Ars Technica');
        expect(ars.url, 'https://feeds.arstechnica.com/arstechnica/index');
        expect(ars.categoryId, isNull); // Uncategorized

        // Check category
        final techCategory =
            result.categories.firstWhere((c) => c.name == 'Tech');
        expect(techCategory.id, isNotEmpty);
        expect(techCategory.color, isNotEmpty);
      });

      test('handles RSS 2.0 and Atom feed formats', () {
        const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline type="rss" text="RSS Feed" title="RSS Feed" xmlUrl="https://example.com/rss" htmlUrl="https://example.com"/>
    <outline type="atom" text="Atom Feed" title="Atom Feed" xmlUrl="https://example.com/atom" htmlUrl="https://example.com/atom"/>
  </body>
</opml>''';

        final result = opmlService.parseOpml(opml);

        expect(result.feeds.length, 2);
        expect(result.feeds[0].url, 'https://example.com/rss');
        expect(result.feeds[1].url, 'https://example.com/atom');
      });

      test('generates consistent colors for categories', () {
        const opml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Tech" title="Tech">
      <outline type="rss" text="Feed1" xmlUrl="https://feed1.com" htmlUrl="https://feed1.com"/>
    </outline>
    <outline text="Tech" title="Tech">
      <outline type="rss" text="Feed2" xmlUrl="https://feed2.com" htmlUrl="https://feed2.com"/>
    </outline>
  </body>
</opml>''';

        final result = opmlService.parseOpml(opml);

        // Same category name should get same color
        expect(result.categories[0].color, equals(result.categories[1].color));
      });

      test('roundtrip: export then import preserves feed data', () {
        final now = DateTime.now();
        final originalFeeds = [
          FeedModel(
            id: 'original-1',
            title: 'Test Feed',
            url: 'https://test.com/feed',
            description: 'https://test.com',
            categoryId: null,
            isDeleted: false,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final originalCategories = <CategoryModel>[];

        // Export
        final exported = opmlService.exportToOpml(originalFeeds, originalCategories);

        // Import
        final result = opmlService.parseOpml(exported);

        // Verify data preserved (ids will be new, but content should match)
        expect(result.feeds.length, 1);
        expect(result.feeds[0].title, 'Test Feed');
        expect(result.feeds[0].url, 'https://test.com/feed');
        expect(result.feeds[0].description, 'https://test.com');
      });
    });
  });
}
