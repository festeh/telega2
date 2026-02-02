import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class MediaThumbnail extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int? selectionIndex;
  final VoidCallback onTap;

  const MediaThumbnail({
    super.key,
    required this.asset,
    required this.isSelected,
    this.selectionIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(200),
            thumbnailFormat: ThumbnailFormat.jpeg,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              );
            },
          ),
          if (asset.type == AssetType.video) _buildDurationOverlay(),
          if (isSelected) _buildSelectedOverlay(),
          if (isSelected && selectionIndex != null) _buildSelectionBadge(),
        ],
      ),
    );
  }

  Widget _buildDurationOverlay() {
    final duration = asset.duration;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    final text = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Positioned(
      bottom: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedOverlay() {
    return Container(color: Colors.black.withValues(alpha: 0.3));
  }

  Widget _buildSelectionBadge() {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${selectionIndex!}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
