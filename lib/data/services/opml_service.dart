import 'package:xml/xml.dart';
import 'package:uuid/uuid.dart';
import '../models/feed_model.dart';
import '../models/category_model.dart';

class OpmlService {
  static const _uuid = Uuid();

  String exportToOpml(List<FeedModel> feeds, List<CategoryModel> categories) {
    final builder = XmlBuilder();
    builder.processing('xml', '1.0');
    builder.element('opml', attributes: {'version': '2.0'}, nest: () {
      builder.element('head', nest: () {
        builder.element('title', nest: 'Real Reader Subscriptions');
        builder.element('dateCreated', nest: DateTime.now().toIso8601String());
      });
      builder.element('body', nest: () {
        // Uncategorized feeds first
        final uncategorized =
            feeds.where((f) => f.categoryId == null && !f.isDeleted).toList();
        for (final feed in uncategorized) {
          _buildFeedOutline(builder, feed);
        }
        // Categorized feeds
        for (final category in categories.where((c) => !c.isDeleted)) {
          final categoryFeeds = feeds
              .where((f) => f.categoryId == category.id && !f.isDeleted)
              .toList();
          if (categoryFeeds.isEmpty) continue;

          builder.element('outline',
              attributes: {
                'text': category.name,
                'title': category.name,
              },
              nest: () {
                for (final feed in categoryFeeds) {
                  _buildFeedOutline(builder, feed);
                }
              });
        }
      });
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }

  void _buildFeedOutline(XmlBuilder builder, FeedModel feed) {
    builder.element('outline',
        attributes: {
          'type': 'rss',
          'text': feed.title,
          'title': feed.title,
          'xmlUrl': feed.url,
          'htmlUrl': feed.description ?? '',
        });
  }

  OpmlImportResult parseOpml(String opml) {
    final document = XmlDocument.parse(opml);
    final outlines = document.findAllElements('outline');
    final feeds = <FeedModel>[];
    final categories = <CategoryModel>[];

    // Track category mapping: category name -> category id
    final categoryNameToId = <String, String>{};

    for (final outline in outlines) {
      final xmlUrl = outline.getAttribute('xmlUrl');

      if (xmlUrl == null) {
        // This is a category (folder)
        final text =
            outline.getAttribute('text') ?? outline.getAttribute('title') ?? '';
        if (text.isNotEmpty) {
          final id = _uuid.v4();
          final color = _generateColorFromName(text);
          final category = CategoryModel(
            id: id,
            name: text,
            color: color,
            sortOrder: categories.length,
            isDeleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          categories.add(category);
          categoryNameToId[text] = id;
        }
      } else {
        // This is a feed
        final title =
            outline.getAttribute('title') ?? outline.getAttribute('text') ?? '';

        // Find parent category by checking if this outline is nested inside a category
        String? categoryId;
        final parent = outline.parent;
        if (parent is XmlElement && parent.name.local == 'outline') {
          final parentText = parent.getAttribute('text') ??
              parent.getAttribute('title') ??
              '';
          categoryId = categoryNameToId[parentText];
        }

        feeds.add(FeedModel(
          id: _uuid.v4(),
          title: title,
          url: xmlUrl,
          description: outline.getAttribute('htmlUrl'),
          categoryId: categoryId,
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }
    return OpmlImportResult(feeds: feeds, categories: categories);
  }

  String _generateColorFromName(String name) {
    // Generate a consistent color from category name
    final colors = [
      '#00497d',
      '#713700',
      '#4a607c',
      '#0061a4',
      '#944a00'
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}

class OpmlImportResult {
  final List<FeedModel> feeds;
  final List<CategoryModel> categories;
  OpmlImportResult({required this.feeds, required this.categories});
}
