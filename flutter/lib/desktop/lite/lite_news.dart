import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'lite_config.dart';

const _kMaxFeedBytes = 512 * 1024;
const _kMaxItems = 50;
const _kFetchTimeout = Duration(seconds: 15);

class LiteNewsItem {
  final String title;
  final String summary;
  final String date;
  final String tag;
  final Uri? link;

  const LiteNewsItem({
    required this.title,
    required this.summary,
    required this.date,
    required this.tag,
    required this.link,
  });

  static LiteNewsItem? fromJson(Map json) {
    String str(String key) {
      final v = json[key];
      return v is String ? v.trim() : '';
    }

    final title = str('title');
    final summary = str('summary').isNotEmpty ? str('summary') : str('content_text');
    if (title.isEmpty && summary.isEmpty) return null;
    var date = str('date');
    if (date.isEmpty) {
      final published = DateTime.tryParse(str('date_published'));
      if (published != null) {
        date = published.toLocal().toIso8601String().substring(0, 10);
      }
    }
    return LiteNewsItem(
      title: title,
      summary: summary,
      date: date,
      tag: str('tag'),
      link: parseLiteNewsUrl(str('url')),
    );
  }
}

/// Accepts `{"items": [...]}` (including JSON Feed 1.1) or a bare list.
List<LiteNewsItem> parseLiteNews(String body) {
  final decoded = jsonDecode(body);
  final raw = decoded is Map ? decoded['items'] : decoded;
  if (raw is! List) {
    throw const FormatException('news feed has no "items" list');
  }
  return raw
      .whereType<Map>()
      .map(LiteNewsItem.fromJson)
      .whereType<LiteNewsItem>()
      .take(_kMaxItems)
      .toList();
}

Future<List<LiteNewsItem>> fetchLiteNews(Uri url) async {
  final client = http.Client();
  try {
    // Redirects are refused so the feed can never be served from plain HTTP.
    final request = http.Request('GET', url)
      ..followRedirects = false
      ..headers['Accept'] = 'application/json'
      ..headers['Cache-Control'] = 'no-cache';
    final streamed = await client.send(request).timeout(_kFetchTimeout);
    if (streamed.statusCode != 200) {
      throw http.ClientException('HTTP ${streamed.statusCode}', url);
    }
    if ((streamed.contentLength ?? 0) > _kMaxFeedBytes) {
      throw http.ClientException('news feed too large', url);
    }
    final response =
        await http.Response.fromStream(streamed).timeout(_kFetchTimeout);
    if (response.bodyBytes.length > _kMaxFeedBytes) {
      throw http.ClientException('news feed too large', url);
    }
    return parseLiteNews(utf8.decode(response.bodyBytes));
  } finally {
    client.close();
  }
}
