// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Offset textOffsetToPosition(RenderParagraph paragraph, int offset) {
  const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
  final Offset localOffset = paragraph.getOffsetForCaret(TextPosition(offset: offset), caret);
  return paragraph.localToGlobal(localOffset);
}

List<TextSelectionPoint> globalize(Iterable<TextSelectionPoint> points, RenderBox box) {
  return points.map<TextSelectionPoint>((TextSelectionPoint point) {
    return TextSelectionPoint(
      box.localToGlobal(point.point),
      point.direction,
    );
  }).toList();
}

void main() {
  group('SelectionArea', () {
    testWidgets('can select single text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SelectionArea(
            child: Text('How are you'),
          ),
        ),
      );
      final RenderParagraph paragraph = tester.renderObject(find.text('How are you')) as RenderParagraph;
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph, 2), kind: PointerDeviceKind.mouse);
      await tester.pump();

      await gesture.moveTo(textOffsetToPosition(paragraph, 4));
      await tester.pump();
      expect(paragraph.textSelection, const TextSelection(baseOffset: 2, extentOffset: 4));

      await gesture.moveTo(textOffsetToPosition(paragraph, 6));
      await tester.pump();
      expect(paragraph.textSelection, const TextSelection(baseOffset: 2, extentOffset: 6));

      // Check backward selection.
      await gesture.moveTo(textOffsetToPosition(paragraph, 1));
      await tester.pump();
      expect(paragraph.textSelection, const TextSelection(baseOffset: 2, extentOffset: 1));

      // Start a new drag
      await gesture.up();
      await gesture.down(textOffsetToPosition(paragraph, 5));
      expect(paragraph.textSelection, null);

      // Selecting across line should select to the end.
      await gesture.moveTo(textOffsetToPosition(paragraph, 5) + const Offset(0.0, 100.0));
      await tester.pump();
      expect(paragraph.textSelection, const TextSelection(baseOffset: 5, extentOffset: 11));

      await gesture.up();
      await gesture.removePointer();
    });
  });
}
