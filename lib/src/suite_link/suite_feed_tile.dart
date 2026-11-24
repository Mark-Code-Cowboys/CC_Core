import 'package:flutter/material.dart';

import 'suite_feed.dart';

/// Settings row: "Add to Kick Rocks automatically". Shows only when Kick
/// Rocks is on the phone, so store builds don't advertise it otherwise.
class SuiteFeedTile extends StatefulWidget {
  /// A row for [feed].
  const SuiteFeedTile({super.key, required this.feed, this.what = 'entries'});

  /// This app's link to Kick Rocks.
  final SuiteFeed feed;

  /// What this app logs, for the subtitle ("meals", "coffee stops").
  final String what;

  @override
  State<SuiteFeedTile> createState() => _SuiteFeedTileState();
}

class _SuiteFeedTileState extends State<SuiteFeedTile> {
  bool? _installed;
  bool _on = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final installed = await widget.feed.kickRocksInstalled();
    final on = await widget.feed.autoSend();
    if (mounted) {
      setState(() {
        _installed = installed;
        _on = on;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_installed != true) return const SizedBox.shrink();
    return SwitchListTile(
      secondary: const Icon(Icons.hiking),
      title: const Text('Add to Kick Rocks automatically'),
      subtitle: Text(
        'New ${widget.what} land on the Kick Rocks trip you were on, '
        'with their pin. Stays on this phone.',
      ),
      value: _on,
      onChanged: (v) {
        setState(() => _on = v);
        widget.feed.setAutoSend(v);
      },
    );
  }
}
