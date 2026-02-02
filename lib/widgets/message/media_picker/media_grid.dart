import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../presentation/providers/media_picker_provider.dart';
import 'media_thumbnail.dart';

class MediaGrid extends ConsumerStatefulWidget {
  final List<AssetEntity> selectedItems;
  final ValueChanged<AssetEntity> onItemTap;

  const MediaGrid({
    super.key,
    required this.selectedItems,
    required this.onItemTap,
  });

  @override
  ConsumerState<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends ConsumerState<MediaGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(mediaPickerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickerState = ref.watch(mediaPickerProvider);
    final assets = pickerState.assets;

    if (assets.isEmpty && !pickerState.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No photos or videos found',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount:
          assets.length +
          (pickerState.isLoading && pickerState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= assets.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final asset = assets[index];
        final selectedIndex = widget.selectedItems.indexOf(asset);
        final isSelected = selectedIndex >= 0;

        return MediaThumbnail(
          asset: asset,
          isSelected: isSelected,
          selectionIndex: isSelected ? selectedIndex + 1 : null,
          onTap: () => widget.onItemTap(asset),
        );
      },
    );
  }
}
