import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'lite_config.dart';
import 'lite_news.dart';
import 'lite_theme.dart';

class LiteNewsPanel extends StatefulWidget {
  final String lang;

  const LiteNewsPanel({Key? key, required this.lang}) : super(key: key);

  @override
  State<LiteNewsPanel> createState() => _LiteNewsPanelState();
}

class _LiteNewsPanelState extends State<LiteNewsPanel> {
  static const _refreshEvery = Duration(minutes: 10);

  late final Uri? _url = liteNewsUrl();
  List<LiteNewsItem>? _items;
  bool _loading = false;
  bool _failed = false;
  Timer? _timer;

  String t(String key) => liteText(widget.lang, key);

  @override
  void initState() {
    super.initState();
    if (_url != null) {
      _load();
      _timer = Timer.periodic(_refreshEvery, (_) => _load());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final url = _url;
    if (url == null || _loading) return;
    setState(() => _loading = true);
    try {
      final items = await fetchLiteNews(url);
      if (mounted) {
        setState(() {
          _items = items;
          _failed = false;
        });
      }
    } catch (e) {
      debugPrint('company news: failed to load $url: $e');
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = LitePalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.panel,
        border: BorderDirectional(start: BorderSide(color: p.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 8, 12),
            child: Row(
              children: [
                Icon(Icons.campaign_rounded, size: 20, color: p.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t('news'),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.text)),
                ),
                if (_url != null)
                  IconButton(
                    tooltip: t('refresh'),
                    splashRadius: 18,
                    onPressed: _loading ? null : _load,
                    icon: Icon(Icons.refresh_rounded, size: 20, color: p.muted),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: p.border),
          Expanded(child: _buildBody(p)),
        ],
      ),
    );
  }

  Widget _buildBody(LitePalette p) {
    final items = _items;
    if (_url == null) {
      return _message(p, Icons.newspaper_rounded, t('news_off'));
    }
    if (items == null) {
      return _failed
          ? _message(p, Icons.cloud_off_rounded, t('news_unavailable'),
              hint: t('news_unavailable_hint'), retry: true)
          : _skeleton(p);
    }
    if (items.isEmpty) {
      return _message(p, Icons.inbox_rounded, t('news_empty'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(t('news_stale'),
                style: TextStyle(fontSize: 12, color: p.warning)),
          ),
        for (final item in items) ...[
          _NewsCard(item: item, palette: p, readMore: t('read_more')),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _message(LitePalette p, IconData icon, String title,
      {String? hint, bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: p.muted.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: p.muted)),
            ],
            if (retry) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loading ? null : _load,
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.primary,
                  side: BorderSide(color: p.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(t('retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skeleton(LitePalette p) {
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: widthFactor,
          child: Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: p.border.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            decoration: p.cardDecoration(radius: 14),
            child: Column(children: [
              bar(0.3, 10),
              bar(0.85, 14),
              bar(1, 10),
              bar(0.6, 10),
            ]),
          ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final LiteNewsItem item;
  final LitePalette palette;
  final String readMore;

  const _NewsCard(
      {required this.item, required this.palette, required this.readMore});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final link = item.link;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: p.cardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.tag.isNotEmpty || item.date.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (item.tag.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(item.tag,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.primary)),
                    ),
                  const Spacer(),
                  if (item.date.isNotEmpty)
                    Text(item.date,
                        textDirection: textDirectionOf(item.date),
                        style: TextStyle(fontSize: 11.5, color: p.muted)),
                ],
              ),
            ),
          if (item.title.isNotEmpty)
            Text(item.title,
                textDirection: textDirectionOf(item.title),
                style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: p.text)),
          if (item.summary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(item.summary,
                  textDirection: textDirectionOf(item.summary),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 13, height: 1.65, color: p.muted)),
            ),
          if (link != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () =>
                    launchUrl(link, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(readMore),
                style: TextButton.styleFrom(foregroundColor: p.primary),
              ),
            ),
        ],
      ),
    );
  }
}
