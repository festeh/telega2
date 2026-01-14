import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/app_providers.dart';
import '../../presentation/state/emoji_sticker_state.dart';
import 'emoji_tab.dart';
import 'sticker_tab.dart';

class EmojiStickerPicker extends ConsumerStatefulWidget {
  final TextEditingController textController;
  final int chatId;
  final VoidCallback? onEmojiSelected;
  final VoidCallback? onStickerSent;
  final VoidCallback? onClose;

  const EmojiStickerPicker({
    super.key,
    required this.textController,
    required this.chatId,
    this.onEmojiSelected,
    this.onStickerSent,
    this.onClose,
  });

  static Future<void> show({
    required BuildContext context,
    required TextEditingController textController,
    required int chatId,
    VoidCallback? onEmojiSelected,
    VoidCallback? onStickerSent,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => EmojiStickerPicker(
          textController: textController,
          chatId: chatId,
          onEmojiSelected: onEmojiSelected,
          onStickerSent: onStickerSent,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  ConsumerState<EmojiStickerPicker> createState() => _EmojiStickerPickerState();
}

class _EmojiStickerPickerState extends ConsumerState<EmojiStickerPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final tab = _tabController.index == 0
          ? PickerTab.emoji
          : PickerTab.sticker;
      ref.read(emojiStickerProvider.notifier).selectTab(tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedTab = ref.watch(
      emojiStickerProvider.select((s) => s.selectedTab),
    );

    // Sync tab controller with state
    final targetIndex = selectedTab == PickerTab.emoji ? 0 : 1;
    if (_tabController.index != targetIndex &&
        !_tabController.indexIsChanging) {
      _tabController.index = targetIndex;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        ),
        title: const Text('Emoji & Stickers'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_emotions_outlined), text: 'Emoji'),
            Tab(icon: Icon(Icons.sticky_note_2_outlined), text: 'Stickers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EmojiTab(
            textController: widget.textController,
            onEmojiSelected: widget.onEmojiSelected,
          ),
          StickerTab(
            chatId: widget.chatId,
            onStickerSent: widget.onStickerSent,
          ),
        ],
      ),
    );
  }
}
