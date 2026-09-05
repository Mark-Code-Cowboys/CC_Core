import 'dart:io';

import 'package:flutter/material.dart';

/// One thumbnail in a [PhotoAttachmentStrip].
class PhotoStripItem {
  /// Creates the item.
  const PhotoStripItem({required this.file, this.caption, this.onRemove});

  /// The stored photo file.
  final File file;

  /// Optional caption shown as a tooltip.
  final String? caption;

  /// Removes the photo; null hides the remove affordance.
  final VoidCallback? onRemove;
}

/// The horizontal photo strip every CC composer shares: thumbnails with
/// remove buttons and one add tile. The app owns capture (camera vs
/// gallery, storage) via [onAdd]; the strip owns only layout.
class PhotoAttachmentStrip extends StatelessWidget {
  /// Creates the strip.
  const PhotoAttachmentStrip({
    super.key,
    required this.items,
    this.onAdd,
    this.addLabel = 'Add photo',
    this.height = 72,
  });

  /// Current photos, in order.
  final List<PhotoStripItem> items;

  /// Starts the app's capture flow; null hides the add tile.
  final VoidCallback? onAdd;

  /// Tooltip/semantics label on the add tile.
  final String addLabel;

  /// Thumbnail height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: item.caption ?? '',
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        item.file,
                        width: height,
                        height: height,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, _) => Container(
                          width: height,
                          height: height,
                          color: scheme.surfaceContainerHighest,
                          child: const Icon(
                              Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                    if (item.onRemove != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: InkWell(
                          onTap: item.onRemove,
                          child: Container(
                            decoration: BoxDecoration(
                              color: scheme.scrim.withValues(alpha: 0.55),
                              borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  topRight: Radius.circular(8)),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.close,
                                size: 16, color: scheme.onInverseSurface),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (onAdd != null)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: height,
                height: height,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Tooltip(
                  message: addLabel,
                  child: Icon(Icons.add_a_photo_outlined,
                      color: scheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
