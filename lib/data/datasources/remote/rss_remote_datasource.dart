import 'package:http/http.dart' as http;
import 'package:webfeed_revised/webfeed_revised.dart';
import '../../models/article_model.dart';

class RssRemoteDatasource {
  final http.Client _client;

  RssRemoteDatasource({http.Client? client}) : _client = client ?? http.Client();

  Future<RssFeed> fetchRssFeed(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return RssFeed.parse(response.body);
    }
    throw Exception('Failed to fetch RSS feed: ${response.statusCode}');
  }

  Future<AtomFeed> fetchAtomFeed(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return AtomFeed.parse(response.body);
    }
    throw Exception('Failed to fetch Atom feed: ${response.statusCode}');
  }

  Future<List<ArticleModel>> fetchAndParseArticles(String feedUrl, String feedId) async {
    try {
      final rssFeed = await fetchRssFeed(feedUrl);
      return _rssItemsToArticles(rssFeed.items ?? [], feedId);
    } on FormatException {
      // Not RSS, try Atom
      final atomFeed = await fetchAtomFeed(feedUrl);
      return _atomItemsToArticles(atomFeed.items ?? [], feedId);
    }
  }

  List<ArticleModel> _rssItemsToArticles(List<RssItem> items, String feedId) {
    return items.map((item) => _rssItemToArticle(item, feedId)).toList();
  }

  List<ArticleModel> _atomItemsToArticles(List<AtomItem> items, String feedId) {
    return items.map((item) => _atomItemToArticle(item, feedId)).toList();
  }

  ArticleModel _rssItemToArticle(RssItem item, String feedId) {
    return ArticleModel(
      id: item.guid ?? item.link ?? DateTime.now().toIso8601String(),
      feedId: feedId,
      title: item.title ?? 'Untitled',
      link: item.link ?? '',
      description: _cleanHtml(item.description ?? ''),
      content: _cleanHtml(item.content?.value ?? item.description ?? ''),
      author: item.author ?? item.dc?.creator,
      imageUrl: item.enclosure?.url ?? _extractImageFromRssItem(item),
      publishedAt: item.pubDate,
      isRead: false,
      isFavorite: false,
      readProgress: 0.0,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  ArticleModel _atomItemToArticle(AtomItem item, String feedId) {
    final link = item.links?.firstWhere(
      (l) => l.rel == 'alternate' || l.rel == null,
      orElse: () => item.links!.first,
    );

    return ArticleModel(
      id: item.id ?? link?.href ?? DateTime.now().toIso8601String(),
      feedId: feedId,
      title: item.title ?? 'Untitled',
      link: link?.href ?? '',
      description: _cleanHtml(item.summary ?? ''),
      content: _cleanHtml(item.content ?? item.summary ?? ''),
      author: item.authors?.map((a) => a.name).join(', '),
      imageUrl: _extractImageFromAtomItem(item),
      publishedAt: (item.published as DateTime?) ?? item.updated,
      isRead: false,
      isFavorite: false,
      readProgress: 0.0,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String? _extractImageFromRssItem(RssItem item) {
    // Try media:content, media:thumbnail, then img src in description
    return item.media?.contents?.firstOrNull?.url
        ?? item.media?.thumbnails?.firstOrNull?.url
        ?? _extractImageFromHtml(item.description ?? '');
  }

  String? _extractImageFromAtomItem(AtomItem item) {
    final content = item.content ?? item.summary ?? '';
    return _extractImageFromHtml(content);
  }

  String? _extractImageFromHtml(String html) {
    final imgMatch = RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(html);
    return imgMatch?.group(1);
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
}
