import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
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
    if (state == AppLifecycleState.resumed) {
      _checkLock();
    } else if (state == AppLifecycleState.paused) {
      _markLocked();
    }
  }

  Future<void> _markLocked() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('app_lock_enabled') ?? false) {
      setState(() => _locked = true);
    }
  }

  Future<void> _checkLockOnLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('app_lock_enabled') ?? false) {
      setState(() => _locked = true);
      await _authenticate();
    }
  }

  Future<void> _checkLock() async {
    if (!_locked) return;
    await _authenticate();
  }

  Future<void> _authenticate() async {
    final auth = LocalAuthentication();
    try {
      final success = await auth.authenticate(
        localizedReason: '请验证身份以使用人情记',
      );
      if (success) setState(() => _locked = false);
    } catch (_) {
      // 设备不支持时忽略
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
