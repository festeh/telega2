import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telega2/core/emoji/emoji_data.dart';
import 'package:telega2/domain/entities/emoji.dart';
import 'package:telega2/presentation/providers/emoji_providers.dart';
import 'package:telega2/widgets/emoji_sticker/emoji_grid.dart';

/// A basic emoji picker with category tabs and custom Telegram-style rendering
/// Replaces emoji_picker_flutter with our custom implementation
class BasicEmojiPicker extends ConsumerStatefulWidget {
  /// Callback when an emoji is selected
  final void Function(String emoji)? onEmojiSelected;

  /// Optional text controller to insert emoji into
  final TextEditingController? textController;

  /// Number of columns in the emoji grid
  final int columns;

  /// Size of each emoji in the grid
  final double emojiSize;

  /// Whether to show the backspace button
  final bool showBackspace;

  const BasicEmojiPicker({
    super.key,
    this.onEmojiSelected,
    this.textController,
    this.columns = 8,
    this.emojiSize = 32.0,
    this.showBackspace = true,
  });

  @override
  ConsumerState<BasicEmojiPicker> createState() => _BasicEmojiPickerState();
}

class _BasicEmojiPickerState extends ConsumerState<BasicEmojiPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<EmojiCategory> _categories = [
    EmojiCategory.recent,
    EmojiCategory.smileys,
    EmojiCategory.people,
    EmojiCategory.animals,
    EmojiCategory.food,
    EmojiCategory.travel,
    EmojiCategory.activities,
    EmojiCategory.objects,
    EmojiCategory.symbols,
    EmojiCategory.flags,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
      initialIndex: 1, // Start at smileys, not recents (might be empty)
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleEmojiSelected(Emoji emoji) {
    // Insert into text controller if provided
    if (widget.textController != null) {
      final controller = widget.textController!;
      final text = controller.text;
      final selection = controller.selection;

      if (selection.isValid) {
        final newText = text.replaceRange(
          selection.start,
          selection.end,
          emoji.char,
        );
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.start + emoji.char.length,
          ),
        );
      } else {
        controller.text = text + emoji.char;
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
      }
    }

    // Call the callback
    widget.onEmojiSelected?.call(emoji.char);

    // Track as recent emoji
    ref.read(emojiRepositoryProvider).recordEmojiUsage(emoji.codepoint);
  }

  void _handleBackspace() {
    if (widget.textController == null) return;

    final controller = widget.textController!;
    final text = controller.text;
    final selection = controller.selection;

    if (text.isEmpty) return;

    if (selection.isValid && selection.start > 0) {
      // Delete character before cursor
      final newText = text.replaceRange(selection.start - 1, selection.start, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 1),
      );
    } else if (text.isNotEmpty) {
      // Delete last character
      controller.text = text.substring(0, text.length - 1);
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Category tabs
        Container(
          color: colorScheme.surfaceContainerLow,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.start,
            tabs: _categories.map((category) {
              return Tab(
                icon: Icon(_getCategoryIcon(category), size: 20),
              );
            }).toList(),
          ),
        ),

        // Emoji grid
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              if (category == EmojiCategory.recent) {
                return _buildRecentEmojisGrid();
              }
              return _buildCategoryGrid(category);
            }).toList(),
          ),
        ),

        // Bottom bar with backspace
        if (widget.showBackspace)
          Container(
            color: colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.backspace_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _handleBackspace,
                  tooltip: 'Backspace',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryGrid(EmojiCategory category) {
    final emojis = EmojiData().getEmojisByCategory(category);

    return EmojiGrid(
      emojis: emojis,
      columns: widget.columns,
      emojiSize: widget.emojiSize,
      onEmojiSelected: _handleEmojiSelected,
    );
  }

  Widget _buildRecentEmojisGrid() {
    final recentEmojisAsync = ref.watch(recentEmojisProvider);

    return recentEmojisAsync.when(
      data: (recentEmojis) {
        if (recentEmojis.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No recent emojis',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return EmojiGrid(
          emojis: recentEmojis,
          columns: widget.columns,
          emojiSize: widget.emojiSize,
          onEmojiSelected: _handleEmojiSelected,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading recent emojis')),
    );
  }

  IconData _getCategoryIcon(EmojiCategory category) {
    switch (category) {
      case EmojiCategory.recent:
        return Icons.access_time;
      case EmojiCategory.smileys:
        return Icons.emoji_emotions_outlined;
      case EmojiCategory.people:
        return Icons.person_outline;
      case EmojiCategory.animals:
        return Icons.pets_outlined;
      case EmojiCategory.food:
        return Icons.fastfood_outlined;
      case EmojiCategory.travel:
        return Icons.directions_car_outlined;
      case EmojiCategory.activities:
        return Icons.sports_soccer_outlined;
      case EmojiCategory.objects:
        return Icons.lightbulb_outline;
      case EmojiCategory.symbols:
        return Icons.emoji_symbols_outlined;
      case EmojiCategory.flags:
        return Icons.flag_outlined;
    }
  }
}

/// A simple inline emoji button that shows a quick picker
class QuickEmojiButton extends ConsumerWidget {
  /// Callback when an emoji is selected
  final void Function(String emoji) onEmojiSelected;

  /// Size of the button
  final double size;

  const QuickEmojiButton({
    super.key,
    required this.onEmojiSelected,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.emoji_emotions_outlined),
      iconSize: size,
      onPressed: () => _showQuickPicker(context),
    );
  }

  void _showQuickPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Picker
            Expanded(
              child: BasicEmojiPicker(
                onEmojiSelected: (emoji) {
                  onEmojiSelected(emoji);
                  Navigator.pop(context);
                },
                showBackspace: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
