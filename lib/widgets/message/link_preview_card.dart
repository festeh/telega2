import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/chat.dart';

class LinkPreviewCard extends StatelessWidget {
  final LinkPreviewInfo preview;
  final bool isOutgoing;

  const LinkPreviewCard({
    super.key,
    required this.preview,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto =
        preview.photo?.path != null && preview.photo!.path!.isNotEmpty;
    final hasTitle = preview.title != null && preview.title!.isNotEmpty;
    final hasDescription =
        preview.description != null && preview.description!.isNotEmpty;
    final hasSiteName =
        preview.siteName != null && preview.siteName!.isNotEmpty;

    // Extract domain from URL for display if no site name
    final displaySiteName = hasSiteName
        ? preview.siteName!
        : Uri.tryParse(preview.url)?.host ?? preview.url;

    return GestureDetector(
      onTap: () => _openUrl(context),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isOutgoing
                  ? colorScheme.onPrimary.withValues(alpha: 0.5)
                  : colorScheme.primary.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo preview
            if (hasPhoto) _buildPhoto(context),

            // Text content
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Site name
                  Text(
                    displaySiteName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isOutgoing
                          ? colorScheme.onPrimary.withValues(alpha: 0.6)
                          : colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Title
                  if (hasTitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview.title!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isOutgoing
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Description
                  if (hasDescription) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isOutgoing
                            ? colorScheme.onPrimary.withValues(alpha: 0.8)
                            : colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final photoPath = preview.photo!.path!;
    final file = File(photoPath);

    return ClipRRect(
      borderRadius: const BorderRadius.only(topRight: Radius.circular(4)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 150,
          maxWidth: double.infinity,
        ),
        child: file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPhotoPlaceholder(colorScheme),
              )
            : _buildPhotoPlaceholder(colorScheme),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(ColorScheme colorScheme) {
    return Container(
      height: 80,
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: colorScheme.onSurfaceVariant,
          size: 32,
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.tryParse(preview.url);
    if (uri == null) return;

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: ${preview.url}')),
        );
      }
    }
  }
}
