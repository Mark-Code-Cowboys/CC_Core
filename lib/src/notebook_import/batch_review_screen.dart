import 'dart:io';

import 'package:flutter/material.dart';

import 'batch_transcribe.dart';

/// Pushes the batch review screen; resolves to the kept items when the
/// user confirms, or null when they back out.
Future<List<BatchScanItem<T>>?> showBatchReviewScreen<T>(
  BuildContext context, {
  required List<BatchScanItem<T>> items,
  required String title,
  String? subtitle,
  required Widget Function(
          BuildContext context, BatchScanItem<T> item, VoidCallback onChanged)
      itemBuilder,
  required String Function(int keptCount) confirmLabel,
}) {
  return Navigator.of(context).push<List<BatchScanItem<T>>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BatchReviewScreen<T>(
        items: items,
        title: title,
        subtitle: subtitle,
        itemBuilder: itemBuilder,
        confirmLabel: confirmLabel,
      ),
    ),
  );
}

/// The confirm-before-save screen of the batch import flow: every
/// transcribed page as a row the user can uncheck or edit, and one
/// bulk-confirm button.
///
/// GUARDRAIL: this screen shows transcribed values verbatim. Rows built
/// by [itemBuilder] let the user *edit* fields; neither this screen nor
/// any row may suggest, correct, or flag values.
class BatchReviewScreen<T> extends StatefulWidget {
  /// Creates the review screen; prefer [showBatchReviewScreen].
  const BatchReviewScreen({
    super.key,
    required this.items,
    required this.title,
    this.subtitle,
    required this.itemBuilder,
    required this.confirmLabel,
  });

  /// The transcribed pages under review.
  final List<BatchScanItem<T>> items;

  /// App bar title ("Scanned scorecards").
  final String title;

  /// One explanatory line under the app bar.
  final String? subtitle;

  /// Renders one item's fields. Call `onChanged` after mutating
  /// `item.value` so the row rebuilds.
  final Widget Function(
          BuildContext context, BatchScanItem<T> item, VoidCallback onChanged)
      itemBuilder;

  /// Label for the confirm button given how many rows are checked.
  final String Function(int keptCount) confirmLabel;

  @override
  State<BatchReviewScreen<T>> createState() => _BatchReviewScreenState<T>();
}

class _BatchReviewScreenState<T> extends State<BatchReviewScreen<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kept = widget.items.where((i) => i.kept).length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                widget.subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: item.kept,
                      onChanged: (v) =>
                          setState(() => item.kept = v ?? false),
                    ),
                    _Thumbnail(path: item.imagePath),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Opacity(
                        opacity: item.kept ? 1 : 0.45,
                        child: widget.itemBuilder(
                            context, item, () => setState(() {})),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: kept == 0
                    ? null
                    : () => Navigator.of(context).pop(
                        widget.items.where((i) => i.kept).toList()),
                child: Text(widget.confirmLabel(kept)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(path),
        width: 48,
        height: 64,
        fit: BoxFit.cover,
        // Transient scan files can vanish (or be fakes in tests).
        errorBuilder: (context, _, _) => Container(
          width: 48,
          height: 64,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.image_not_supported_outlined, size: 20),
        ),
      ),
    );
  }
}
