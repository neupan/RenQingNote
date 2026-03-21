import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'pages/home/home_page.dart';

class RenQingNoteApp extends StatefulWidget {
  const RenQingNoteApp({super.key});

  @override
  State<RenQingNoteApp> createState() => _RenQingNoteAppState();
}

class _RenQingNoteAppState extends State<RenQingNoteApp>
    with WidgetsBindingObserver {
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockOnLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.auth('生命周期变化: $state');
    if (state == AppLifecycleState.paused) {
      _markLocked();
    }
    // 移除 resumed 时的自动认证，避免原生弹窗导致的无限死循环
  }

  Future<void> _markLocked() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('app_lock_enabled') ?? false;
    AppLogger.auth('标记锁定: app_lock_enabled=$enabled');
    if (enabled) {
      setState(() => _locked = true);
    }
  }

  Future<void> _checkLockOnLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('app_lock_enabled') ?? false;
    AppLogger.auth('启动检查: app_lock_enabled=$enabled');
    if (enabled) {
      setState(() => _locked = true);
      // 启动时也改为不自动弹出，统一由用户点击按钮触发
    }
  }

  Future<void> _authenticate() async {
    final auth = LocalAuthentication();
    try {
      final success = await auth.authenticate(
        localizedReason: '请验证身份以使用人情记',
      );
      AppLogger.auth('认证结果: ${success ? "success" : "failed"}');
      if (success) setState(() => _locked = false);
    } catch (e) {
      AppLogger.error('认证异常', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '人情记',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: _locked ? _LockScreen(onUnlock: _authenticate) : const HomePage(),
    );
  }
}

class _LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('应用已锁定'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint),
              label: const Text('验证解锁'),
            ),
          ],
        ),
      ),
    );
  }
}
