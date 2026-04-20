import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/telegram_client_provider.dart';
import 'chat_helpers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _tdlibVersion;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final client = ref.read(telegramClientProvider);
    final version = await client.getTdlibVersion();
    if (!mounted) return;
    setState(() {
      _tdlibVersion = version;
      _loading = false;
    });
  }

  Future<void> _copyVersion() async {
    final version = _tdlibVersion;
    if (version == null) return;
    await Clipboard.setData(ClipboardData(text: version));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TDLib version copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.6);
    final versionText = _loading
        ? 'Loading…'
        : (_tdlibVersion ?? 'unknown');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: mutedColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('TDLib version'),
            subtitle: Text(versionText),
            trailing: _tdlibVersion == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy version',
                    onPressed: _copyVersion,
                  ),
            onLongPress: _tdlibVersion == null ? null : _copyVersion,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text(
              'Log out',
              style: TextStyle(color: colorScheme.error),
            ),
            onTap: () => showLogoutDialog(context, ref),
          ),
        ],
      ),
    );
  }
}
