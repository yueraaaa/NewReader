import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webfeed_revised/webfeed_revised.dart';
import '../../models/article_model.dart';
import '../../../core/utils/html_utils.dart';

class RssRemoteDatasource {
  final http.Client _client;

  RssRemoteDatasource({http.Client? client}) : _client = client ?? http.Client();

  String _decodeBody(http.Response response) {
    // Try to get charset from Content-Type header
    final contentType = response.headers['content-type'] ?? '';
    String? charset;

    if (contentType.contains('charset=')) {
      charset = RegExp(r'charset=([^\s;]+)').firstMatch(contentType)?[1];
    }

    // Decode body based on charset or try to detect
    try {
      if (charset != null && charset.toLowerCase() != 'utf-8') {
        // Convert from specified encoding to UTF-8
        final converter = Encoding.getByName(charset);
        if (converter != null) {
          return converter.decode(response.bodyBytes);
        }
      }
    } catch (_) {}

    // Try GB2312/GBK (common Chinese encodings)
    try {
      // Check if it's valid UTF-8 first
      utf8.decode(response.bodyBytes);
      return utf8.decode(response.bodyBytes);
    } catch (_) {
      // Not valid UTF-8, try GB2312
      try {
        final gbkDecoder = Encoding.getByName('gb2312');
        if (gbkDecoder != null) {
          return gbkDecoder.decode(response.bodyBytes);
        }
      } catch (_) {}
    }

    // Fallback: use latin1 (HTTP default)
    return latin1.decode(response.bodyBytes);
  }

  Future<RssFeed> fetchRssFeed(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final body = _decodeBody(response);
      return RssFeed.parse(body);
    }
    throw Exception('Failed to fetch RSS feed: ${response.statusCode}');
  }

  Future<AtomFeed> fetchAtomFeed(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final body = _decodeBody(response);
      return AtomFeed.parse(body);
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
    final articleId = item.guid ?? '${feedId}_${item.pubDate?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
    final rawDescription = HtmlUtils.stripHtml(item.description ?? '');
    // Get raw content, but only use it if it's meaningfully different from description
    final rawContent = item.content?.value;
    String content;
    if (rawContent != null && rawContent.isNotEmpty) {
      final cleanedContent = HtmlUtils.stripHtml(rawContent);
      // Only use content if it's at least 50% longer than description (meaningful content)
      if (cleanedContent.length > rawDescription.length * 1.5) {
        content = cleanedContent;
      } else {
        content = rawDescription;
      }
    } else {
      content = rawDescription;
    }

    return ArticleModel(
      id: articleId,
      feedId: feedId,
      title: item.title ?? 'Untitled',
      link: item.link ?? '',
      description: rawDescription,
      content: content,
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
    final articleId = item.id ?? '${feedId}_${(item.published as DateTime?)?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

    return ArticleModel(
      id: articleId,
      feedId: feedId,
      title: item.title ?? 'Untitled',
      link: link?.href ?? '',
      description: HtmlUtils.stripHtml(item.summary ?? ''),
      content: HtmlUtils.stripHtml(item.content ?? item.summary ?? ''),
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
}
