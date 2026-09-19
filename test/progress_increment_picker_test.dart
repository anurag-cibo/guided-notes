import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_notes/features/todos/presentation/progress_increment_picker.dart';

void main() {
  testWidgets(
    'two wheels adapt fractional steps and preserve selected values',
    (tester) async {
      var value = 2.5;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressIncrementPicker(
              value: value,
              onChanged: (next) => value = next,
            ),
          ),
        ),
      );
      CupertinoPicker whole() =>
          tester.widget<CupertinoPicker>(find.byType(CupertinoPicker).first);
      CupertinoPicker fraction() =>
          tester.widget<CupertinoPicker>(find.byType(CupertinoPicker).last);
      expect(whole().scrollController!.selectedItem, 2);
      expect(fraction().scrollController!.selectedItem, 3);
      fraction().scrollController!.jumpToItem(4);
      await tester.pumpAndSettle();
      expect(value, 2.6);
      whole().scrollController!.jumpToItem(3);
      await tester.pumpAndSettle();
      expect(value, 3.5);
      fraction().scrollController!.jumpToItem(3);
      await tester.pumpAndSettle();
      expect(value, 3.75);
      whole().scrollController!.jumpToItem(4);
      await tester.pumpAndSettle();
      expect(value, 4.5);
      whole().scrollController!.jumpToItem(5);
      await tester.pumpAndSettle();
      expect(value, 5);
      whole().scrollController!.jumpToItem(0);
      await tester.pumpAndSettle();
      expect(value, 0.1);
      fraction().scrollController!.jumpToItem(2);
      await tester.pumpAndSettle();
      expect(value, 0.25);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('wheel respects both bounds with large text in light and dark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final brightness in Brightness.values) {
      for (final initial in [0, 100]) {
        var selected = initial.toDouble();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: ProgressIncrementPicker(
                  key: ValueKey('$brightness-$initial'),
                  value: initial.toDouble(),
                  onChanged: (value) => selected = value,
                ),
              ),
            ),
          ),
        );
        await tester.drag(
          find.byType(CupertinoPicker).first,
          Offset(0, initial == 0 ? 200 : -200),
        );
        await tester.pumpAndSettle();
        expect(selected, initial);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
