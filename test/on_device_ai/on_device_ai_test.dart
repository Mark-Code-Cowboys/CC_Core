import 'package:cc_core/cc_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final labeler = LineLabeler(
    model: FakeOnDeviceTextModel(
      answers: ['1: T\n2: I => 1 onion\n3: S\n4: X\nnoise\n9: I'],
    ),
    task: 'the lines of a scanned card',
    labels: const [
      LineLabelSpec('T', 'the title'),
      LineLabelSpec('I', 'an item line', allowReading: true),
      LineLabelSpec('S', 'a step'),
      LineLabelSpec('X', 'anything else'),
    ],
    readingInstructions: 'fix OCR misreads in the amount.',
  );
  const text = 'Chili\nl onion\nBrown it.\np. 42';

  test('numberedLines and prompt', () {
    expect(numberedLines(' a \n\n b '), ['a', 'b']);
    final p = labeler.buildPrompt(numberedLines(text));
    expect(p, contains('1: Chili'));
    expect(p, contains('For I lines you MAY add a reading'));
    expect(p, contains('fix OCR misreads'));
  });

  test(
    'label: readings only where allowed, skipped lines are other, junk ignored',
    () async {
      final l = await labeler.label(text, requiredCode: 'I');
      expect(l!.lines.map((x) => x.code), ['T', 'I', 'S', 'X']);
      expect(l.lines[1].reading, '1 onion');
      expect(l.lines[1].text, 'l onion', reason: 'the original line is kept');
      expect(l.withCode('S').single.text, 'Brown it.');
    },
  );

  test('unusable answers and unavailable models give null', () async {
    final noItems = LineLabeler(
      model: FakeOnDeviceTextModel(answers: ['1: T']),
      task: 't',
      labels: labeler.labels,
    );
    expect(await noItems.label(text, requiredCode: 'I'), isNull);
    final off = LineLabeler(
      model: FakeOnDeviceTextModel(available: false),
      task: 't',
      labels: labeler.labels,
    );
    expect(await off.label(text, requiredCode: 'I'), isNull);
  });

  test('MethodChannelTextModel maps the channel contract', () async {
    const channel = MethodChannel('test/on_device_ai');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isAvailable') return true;
      if (call.method == 'generate') {
        return 'echo:${(call.arguments as Map)['prompt']}';
      }
      return null;
    });
    final m = MethodChannelTextModel(channel);
    expect(await m.isAvailable(), isTrue);
    expect(await m.generate('hi'), 'echo:hi');
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isAvailable') return true;
      throw PlatformException(code: 'generation_failed', message: 'boom');
    });
    expect(() => m.generate('hi'), throwsA(isA<OnDeviceModelException>()));
    messenger.setMockMethodCallHandler(channel, null);
    expect(await m.isAvailable(), isFalse);
    expect(await m.generate('hi'), isNull);
  });
}
