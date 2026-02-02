import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../presentation/providers/media_picker_provider.dart';
import 'media_grid.dart';

class MediaPickerPanel extends ConsumerStatefulWidget {
  final Future<void> Function(List<AssetEntity> items, String? caption) onSend;

  const MediaPickerPanel({super.key, required this.onSend});

  @override
  ConsumerState<MediaPickerPanel> createState() => _MediaPickerPanelState();

  static void show({
    required BuildContext context,
    required Future<void> Function(List<AssetEntity> items, String? caption)
    onSend,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaPickerPanel(onSend: onSend),
    );
  }
}

class _MediaPickerPanelState extends ConsumerState<MediaPickerPanel>
    with WidgetsBindingObserver {
  final List<AssetEntity> _selectedItems = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pickerState = ref.read(mediaPickerProvider);
      if (pickerState.permission == MediaPickerPermission.notDetermined) {
        ref.read(mediaPickerProvider.notifier).requestPermissionAndLoad();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final pickerState = ref.read(mediaPickerProvider);
      if (pickerState.permission == MediaPickerPermission.denied) {
        ref.read(mediaPickerProvider.notifier).requestPermissionAndLoad();
      }
    }
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      final index = _selectedItems.indexOf(asset);
      if (index >= 0) {
        _selectedItems.removeAt(index);
      } else if (_selectedItems.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 10 items'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        _selectedItems.add(asset);
      }
    });
  }

  Future<void> _send() async {
    if (_selectedItems.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await widget.onSend(_selectedItems, null);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isLinux || Platform.isWindows || Platform.isMacOS;

    return DraggableScrollableSheet(
      initialChildSize: isDesktop ? 0.3 : 0.5,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              _buildActionRow(),
              const Divider(height: 1),
              Expanded(child: _buildContent(isDesktop)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Spacer(),
          if (_selectedItems.isNotEmpty)
            _isSending
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: _send,
                    icon: const Icon(Icons.send, size: 18),
                    label: Text('Send (${_selectedItems.length})'),
                  ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDesktop) {
    if (isDesktop) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Gallery is not available on desktop.\nUse Camera or Document buttons above.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final pickerState = ref.watch(mediaPickerProvider);

    if (pickerState.permission == MediaPickerPermission.denied) {
      return _buildPermissionDenied();
    }

    if (pickerState.permission == MediaPickerPermission.notDetermined &&
        pickerState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return MediaGrid(
      selectedItems: _selectedItems,
      onItemTap: _toggleSelection,
    );
  }

  Widget _buildPermissionDenied() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Permission required to access photos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => PhotoManager.openSetting(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
