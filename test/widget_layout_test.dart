import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Widgets are inflated by RemoteViews, which only accepts a short list of
/// view classes (a bare View tag works on Android 12+ only). One unsupported
/// tag makes the widget silently not appear on older phones.
void main() {
  const allowed = {
    'FrameLayout', 'LinearLayout', 'RelativeLayout', 'GridLayout', 'AnalogClock', 'Button',
    'Chronometer', 'ImageButton', 'ImageView', 'ProgressBar', 'TextView', 'ViewFlipper',
    'ListView', 'GridView', 'StackView', 'AdapterViewFlipper', 'TextClock',
  };

  test('widget layouts only use views RemoteViews can inflate on every Android version', () {
    final dir = Directory('android/app/src/main/res/layout');
    final files = dir.listSync().whereType<File>().where((f) => f.uri.pathSegments.last.startsWith('widget_')).toList();
    expect(files, isNotEmpty);
    for (final f in files) {
      final tags = RegExp(r'<([A-Za-z][\w.]*)').allMatches(f.readAsStringSync()).map((m) => m.group(1)!);
      for (final t in tags) {
        expect(allowed.contains(t), true, reason: '${f.path}: <$t> is not allowed in a widget layout');
      }
    }
  });
}
