import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';

/// Build with `--dart-define=DOLPHINDESK_LITE=true` to get the customer-only UI.
const bool isDolphinDeskLite = bool.fromEnvironment('DOLPHINDESK_LITE');

/// Build-time default for the news feed; the `dolphindesk-news-url` option
/// (custom client settings or `--option`) overrides it without a rebuild.
const String _kBuildNewsUrl = String.fromEnvironment('DOLPHINDESK_NEWS_URL');
const String kOptionLiteNewsUrl = 'dolphindesk-news-url';

Uri? liteNewsUrl() {
  final configured = bind.mainGetOptionSync(key: kOptionLiteNewsUrl).trim();
  return parseLiteNewsUrl(configured.isNotEmpty ? configured : _kBuildNewsUrl);
}

/// Only HTTPS is accepted so the feed cannot be swapped in transit.
Uri? parseLiteNewsUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}

String liteLanguage() {
  var lang = bind.mainGetLocalOption(key: kCommConfKeyLang);
  if (lang.isEmpty || lang == 'default') lang = Platform.localeName;
  return lang.split(RegExp('[-_.]')).first.toLowerCase();
}

const _rtlLanguages = {'fa', 'ar', 'he', 'ur'};

TextDirection liteDirection(String lang) =>
    _rtlLanguages.contains(lang) ? TextDirection.rtl : TextDirection.ltr;

final _rtlChar = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]');
final _ltrChar = RegExp(r'[A-Za-zÀ-ɏ]');

/// Direction of the first strong character, so a Persian headline in an
/// English UI (or the reverse) still aligns and wraps correctly.
TextDirection? textDirectionOf(String text) {
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (_rtlChar.hasMatch(ch)) return TextDirection.rtl;
    if (_ltrChar.hasMatch(ch)) return TextDirection.ltr;
  }
  return null;
}

const _en = <String, String>{
  'subtitle': 'Remote support',
  'id_label': 'Your support ID',
  'id_hint':
      'Tell this ID to your support agent so they can send a connection request.',
  'copy_id': 'Copy ID',
  'copied': 'ID copied',
  'otp': 'One-time password',
  'copy': 'Copy',
  'otp_copied': 'Password copied',
  'online': 'Online',
  'connecting': 'Connecting…',
  'offline': 'Offline',
  'offline_hint': 'Check your internet connection.',
  'stopped': 'Service stopped',
  'start': 'Start',
  'secure_title': 'Your control, your approval',
  'secure_body':
      'Share these details only with our official support team. You can end a remote session at any time.',
  'install_body':
      'Install {} on this computer for a more reliable support connection.',
  'install': 'Install',
  'news': 'Dolphin News',
  'refresh': 'Refresh',
  'news_unavailable': 'News is unavailable right now',
  'news_unavailable_hint': 'We\'ll try again shortly.',
  'news_stale': 'Couldn\'t refresh. Showing earlier news.',
  'news_empty': 'No news yet',
  'news_off': 'Dolphin news isn\'t set up yet',
  'retry': 'Try again',
  'read_more': 'Read more',
};

const _fa = <String, String>{
  'subtitle': 'پشتیبانی از راه دور',
  'id_label': 'شناسه پشتیبانی شما',
  'id_hint':
      'این شناسه را به کارشناس پشتیبانی اعلام کنید تا درخواست اتصال ارسال کند.',
  'copy_id': 'کپی شناسه',
  'copied': 'شناسه کپی شد',
  'otp': 'رمز یک‌بارمصرف',
  'copy': 'کپی',
  'otp_copied': 'رمز کپی شد',
  'online': 'آنلاین',
  'connecting': 'در حال اتصال…',
  'offline': 'آفلاین',
  'offline_hint': 'اتصال اینترنت خود را بررسی کنید.',
  'stopped': 'سرویس متوقف است',
  'start': 'راه‌اندازی',
  'secure_title': 'کنترل و تأیید با شماست',
  'secure_body':
      'این اطلاعات را فقط در اختیار تیم پشتیبانی رسمی ما قرار دهید. هر زمان بخواهید می‌توانید اتصال را قطع کنید.',
  'install_body':
      'برای اتصال پایدارتر پشتیبانی، {} را روی این رایانه نصب کنید.',
  'install': 'نصب',
  'news': 'اخبار شرکت',
  'refresh': 'به‌روزرسانی',
  'news_unavailable': 'در حال حاضر دریافت اخبار ممکن نیست',
  'news_unavailable_hint': 'کمی بعد دوباره تلاش می‌کنیم.',
  'news_stale': 'به‌روزرسانی انجام نشد؛ اخبار قبلی نمایش داده می‌شود.',
  'news_empty': 'هنوز خبری منتشر نشده است',
  'news_off': 'بخش اخبار هنوز تنظیم نشده است',
  'retry': 'تلاش دوباره',
  'read_more': 'ادامه مطلب',
};

String liteText(String lang, String key) =>
    (lang == 'fa' ? _fa[key] : null) ?? _en[key] ?? key;
