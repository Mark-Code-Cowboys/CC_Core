import 'package:flutter/services.dart';

/// The phone's own language model — Gemini Nano through ML Kit's
/// Prompt API on Android, Apple's Foundation Models on iOS 26+ —
/// behind one seam. No key, no network, no cost; a phone without a
/// model reports unavailable and callers fall back. The native halves
/// live in each app (see doc/on_device_ai.md for the reference
/// Kotlin/Swift); this is the Dart side plus a fake.
abstract class OnDeviceTextModel {
  /// Whether a usable model exists on this phone right now.
  Future<bool> isAvailable();

  /// The model's answer to [prompt], or null when unavailable.
  Future<String?> generate(String prompt);
}

/// Thrown by [MethodChannelTextModel.generate] when the native side
/// reports a generation failure (as opposed to being absent).
class OnDeviceModelException implements Exception {
  /// Creates the exception with the native error [message].
  const OnDeviceModelException(this.message);

  /// The native error text.
  final String message;

  @override
  String toString() => message;
}

/// [OnDeviceTextModel] over a method channel answering `isAvailable`
/// and `generate({prompt})` — the contract the reference native code
/// implements. The channel name is per app
/// ("com.example.app/on_device_ai").
class MethodChannelTextModel implements OnDeviceTextModel {
  /// Over an existing [channel].
  MethodChannelTextModel(this.channel);

  /// Over a new channel called [channelName].
  MethodChannelTextModel.named(String channelName)
    : channel = MethodChannel(channelName);

  /// The app's channel; its native side answers `isAvailable` and
  /// `generate`.
  final MethodChannel channel;

  @override
  Future<bool> isAvailable() async {
    try {
      return await channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<String?> generate(String prompt) async {
    try {
      return await channel.invokeMethod<String>('generate', {'prompt': prompt});
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      throw OnDeviceModelException(
        'On-device AI failed: ${e.message ?? e.code}',
      );
    }
  }
}

/// Test double: canned answers in order (the last one repeats), or
/// unavailable.
class FakeOnDeviceTextModel implements OnDeviceTextModel {
  /// Canned [answers] in order (the last repeats), or unavailable.
  FakeOnDeviceTextModel({this.answers = const [], this.available = true});

  /// Answers served in order.
  final List<String> answers;

  /// What [isAvailable] reports.
  final bool available;

  /// Every prompt passed to [generate].
  final prompts = <String>[];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> generate(String prompt) async {
    if (!available) return null;
    prompts.add(prompt);
    if (answers.isEmpty) return null;
    final i = prompts.length - 1;
    return answers[i < answers.length ? i : answers.length - 1];
  }
}
