import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventkuy/core/motion.dart';

class _DurationProbe extends StatelessWidget {
  const _DurationProbe({required this.normal});

  final Duration normal;

  @override
  Widget build(BuildContext context) {
    final d = AppMotion.duration(context, normal);
    return Text(d == Duration.zero ? 'zero' : normal.inMilliseconds.toString());
  }
}

Widget _app({
  required bool disableAnimations,
  required Duration normal,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: _DurationProbe(normal: normal),
    ),
  );
}

void main() {
  group('AppMotion.reduced', () {
    testWidgets('false saat disableAnimations tidak aktif', (tester) async {
      await tester.pumpWidget(
        _app(disableAnimations: false, normal: const Duration(milliseconds: 300)),
      );
      expect(find.text('300'), findsOneWidget);
    });

    testWidgets('true saat disableAnimations aktif', (tester) async {
      await tester.pumpWidget(
        _app(disableAnimations: true, normal: const Duration(milliseconds: 300)),
      );
      expect(find.text('zero'), findsOneWidget);
    });
  });
}
