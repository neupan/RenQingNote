import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'event_manage_page.dart';
import 'backup_restore_page.dart';

final _lockEnabledProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('app_lock_enabled') ?? false;
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockAsync = ref.watch(_lockEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          const _SectionHeader(title: '功能'),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('事件管理'),
            subtitle: const Text('管理自定义事件类型'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EventManagePage()),
            ),
          ),
          const Divider(),
          const _SectionHeader(title: '安全'),
          lockAsync.when(
            data: (enabled) => SwitchListTile(
              secondary: const Icon(Icons.lock),
              title: const Text('隐私锁'),
              subtitle: const Text('每次打开 APP 需要生物识别验证'),
              value: enabled,
              onChanged: (v) => _toggleLock(context, ref, v),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.lock),
              title: Text('隐私锁'),
              trailing: SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(),
          const _SectionHeader(title: '数据'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('数据管理'),
            subtitle: const Text('导出 CSV / 备份 / 恢复'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupRestorePage()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLock(
      BuildContext context, WidgetRef ref, bool enable) async {
    if (enable) {
      final auth = LocalAuthentication();
      final canAuth = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuth) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('设备不支持生物识别')),
          );
        }
        return;
      }
      final authenticated = await auth.authenticate(
        localizedReason: '启用隐私锁需要验证身份',
      );
      if (!authenticated) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', enable);
    ref.invalidate(_lockEnabledProvider);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}
