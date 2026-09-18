import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/features/todos/presentation/progress_increment_picker.dart';

void main() {
  testWidgets('wheel respects both bounds with large text in light and dark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final brightness in Brightness.values) {
      for (final initial in [1, 100]) {
        var selected = initial;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: ProgressIncrementPicker(
                  key: ValueKey('$brightness-$initial'),
                  value: initial,
                  onChanged: (value) => selected = value,
                ),
              ),
            ),
          ),
        );
        await tester.drag(
          find.byType(CupertinoPicker),
          Offset(0, initial == 1 ? 200 : -200),
        );
        await tester.pumpAndSettle();
        expect(selected, initial);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
