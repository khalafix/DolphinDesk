import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'lite_config.dart';
import 'lite_news_panel.dart';
import 'lite_theme.dart';

/// Customer-only home view. It replaces only what `DesktopHomePage` draws;
/// that page's state still owns the ID poller and window message handling,
/// and incoming connections are still approved in the separate `--cm` window.
class LiteHomeView extends StatefulWidget {
  final String systemError;

  const LiteHomeView({Key? key, required this.systemError}) : super(key: key);

  @override
  State<LiteHomeView> createState() => _LiteHomeViewState();
}

class _LiteHomeViewState extends State<LiteHomeView> {
  final _svcStopped = Get.find<RxBool>(tag: 'stop-service');
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _statusTimer = periodic_immediate(const Duration(seconds: 1), _updateStatus);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  // Same source as OnlineStatusWidget, which the Lite view does not show.
  Future<void> _updateStatus() async {
    final status =
        jsonDecode(await bind.mainGetConnectStatus()) as Map<String, dynamic>;
    final statusNum = status['status_num'];
    stateGlobal.svcStatus.value = statusNum == 1
        ? SvcStatus.ready
        : statusNum == 0
            ? SvcStatus.connecting
            : SvcStatus.notReady;
    final count = status['video_conn_count'];
    if (count is int) stateGlobal.videoConnCount.value = count;
  }

  @override
  Widget build(BuildContext context) {
    final lang = liteLanguage();
    String t(String key) => liteText(lang, key);
    final p = LitePalette.of(context);
    return Directionality(
      textDirection: liteDirection(lang),
      child: ColoredBox(
        color: p.background,
        child: LayoutBuilder(builder: (context, constraints) {
          final showNews = constraints.maxWidth >= 760;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildMain(p, t)),
              if (showNews)
                SizedBox(
                  width: constraints.maxWidth >= 1000 ? 380 : 330,
                  child: LiteNewsPanel(lang: lang),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMain(LitePalette p, String Function(String) t) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(p, t),
                    const SizedBox(height: 24),
                    _buildIdCard(p, t),
                    const SizedBox(height: 16),
                    ..._buildNotices(p, t),
                    _buildSecurityNote(p, t),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LitePalette p, String Function(String) t) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: p.border),
          ),
          child: loadIcon(44),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bind.mainGetAppNameSync(),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: p.text),
              ),
              Text(t('subtitle'),
                  style: TextStyle(fontSize: 13, color: p.muted)),
            ],
          ),
        ),
        _buildStatusPill(p, t),
      ],
    );
  }

  Widget _buildStatusPill(LitePalette p, String Function(String) t) {
    return Obx(() {
      final status = stateGlobal.svcStatus.value;
      final (label, color) = _svcStopped.value
          ? (t('stopped'), p.danger)
          : switch (status) {
              SvcStatus.ready => (t('online'), p.success),
              SvcStatus.connecting => (t('connecting'), p.warning),
              SvcStatus.notReady => (t('offline'), p.danger),
            };
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(p.dark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );
    });
  }

  Widget _buildIdCard(LitePalette p, String Function(String) t) {
    final model = gFFI.serverModel;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: p.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t('id_label'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: p.muted)),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: model.serverId,
            builder: (context, value, _) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.text,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: p.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _copyId(t),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(t('copy_id'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: p.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(t('id_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, height: 1.6, color: p.muted)),
          ChangeNotifierProvider.value(
            value: model,
            child: Consumer<ServerModel>(
              builder: (context, model, _) {
                // Same condition as the full UI's password board.
                final showOneTime = model.approveMode != 'click' &&
                    model.verificationMethod != kUsePermanentPassword;
                return showOneTime
                    ? _buildPasswordRow(p, t, model)
                    : const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRow(
      LitePalette p, String Function(String) t, ServerModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Divider(height: 1, color: p.border),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.key_rounded, size: 18, color: p.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t('otp'),
                  style: TextStyle(fontSize: 13, color: p.muted)),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: model.serverPasswd,
              builder: (context, value, _) => Text(
                value.text,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: p.text),
              ),
            ),
            IconButton(
              tooltip: t('copy'),
              splashRadius: 18,
              icon: Icon(Icons.copy_rounded, size: 18, color: p.primary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: model.serverPasswd.text));
                showToast(t('otp_copied'));
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _copyId(String Function(String) t) async {
    final id = await bind.mainGetMyId();
    if (id.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: id));
    showToast(t('copied'));
  }

  List<Widget> _buildNotices(LitePalette p, String Function(String) t) {
    return [
      Obx(() {
        if (_svcStopped.value) {
          return _notice(p,
              icon: Icons.pause_circle_outline_rounded,
              color: p.danger,
              text: t('stopped'),
              action: t('start'),
              onAction: () => start_service(true));
        }
        if (stateGlobal.svcStatus.value == SvcStatus.notReady) {
          return _notice(p,
              icon: Icons.wifi_off_rounded,
              color: p.warning,
              text: t('offline_hint'));
        }
        return const SizedBox.shrink();
      }),
      if (widget.systemError.isNotEmpty)
        _notice(p,
            icon: Icons.error_outline_rounded,
            color: p.danger,
            text: widget.systemError),
      if (isWindows &&
          !bind.isDisableInstallation() &&
          !bind.mainIsInstalled() &&
          bind.mainGetBuildinOption(key: kOptionHideHelpCards) != 'Y')
        _notice(p,
            icon: Icons.download_rounded,
            color: p.primary,
            text: t('install_body')
                .replaceAll('{}', bind.mainGetAppNameSync()),
            action: t('install'), onAction: () async {
          await rustDeskWinManager.closeAllSubWindows();
          bind.mainGotoInstall();
        }),
    ];
  }

  Widget _notice(LitePalette p,
      {required IconData icon,
      required Color color,
      required String text,
      String? action,
      VoidCallback? onAction}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(p.dark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, height: 1.5, color: p.text)),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(LitePalette p, String Function(String) t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded, size: 22, color: p.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('secure_title'),
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: p.text)),
                const SizedBox(height: 4),
                Text(t('secure_body'),
                    style: TextStyle(
                        fontSize: 12.5, height: 1.6, color: p.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
