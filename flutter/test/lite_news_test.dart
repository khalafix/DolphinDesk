import 'package:flutter_hbb/desktop/lite/lite_config.dart';
import 'package:flutter_hbb/desktop/lite/lite_news.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('news feed URL must be HTTPS', () {
    expect(parseLiteNewsUrl('https://example.com/news.json'), isNotNull);
    expect(parseLiteNewsUrl('http://example.com/news.json'), isNull);
    expect(parseLiteNewsUrl('file:///C:/news.json'), isNull);
    expect(parseLiteNewsUrl(''), isNull);
  });

  test('parses simple and JSON Feed items, dropping unsafe links', () {
    final items = parseLiteNews('''
{"items": [
  {"title": "سرویس جدید", "summary": "متن خبر", "date": "۱۴۰۵/۰۸/۲۳",
   "tag": "اطلاعیه", "url": "https://example.com/a"},
  {"title": "Maintenance", "content_text": "Tonight 22:00",
   "date_published": "2026-11-14T10:00:00Z", "url": "http://example.com/b"},
  {"tag": "empty"}
]}''');
    expect(items, hasLength(2));
    expect(items[0].title, 'سرویس جدید');
    expect(items[0].link, Uri.parse('https://example.com/a'));
    expect(items[1].summary, 'Tonight 22:00');
    expect(items[1].date, startsWith('2026-11-1'));
    expect(items[1].link, isNull);
  });
}
