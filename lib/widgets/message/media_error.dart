import 'package:flutter/material.dart';
import '../../core/constants/ui_constants.dart';

/// Informative error tile shown in place of a media widget when the file
/// cannot be displayed — download failed, playback init failed, or the
/// message arrived without an attached file.
class MediaError extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const MediaError({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.errorContainer,
      padding: const EdgeInsets.all(Spacing.md),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: IconSize.lg,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onErrorContainer,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                details!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onErrorContainer.withValues(
                    alpha: Opacities.medium,
                  ),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: Spacing.sm),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
