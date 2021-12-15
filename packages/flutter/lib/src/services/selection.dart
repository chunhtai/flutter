// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/cupertino.dart';

/// The result after handling a selection event. This is used by the parent
/// of multiple [Selectable]s to determine how a selection expand across its
/// selectable children.
enum SelectionResult {
  /// There is nothing left to select forward, and further selection should
  /// extend to the next selectable.
  next,
  /// Selection does not reach this selectable and should look previous
  /// selectable.
  previous,
  /// Selection edge ends in this selectable. part of the selectable may or may
  /// not be selected, but there are still content to select forward or backward.
  end,
  /// The result can't be determine in this frame. This is typically returned
  /// when the subtree is scrolling to reveal more content.
  pending,
  /// There is no result for the selection event. This is returned when the
  /// selection result is not applicable, e.g. [DragSelectionStartEvent] or
  /// [DragSelectionEndEvent]
  none,
}

/// An object that can be selected by the [SelectionArea] widget.
///
/// This object receives selection events and is responsible to draw selection
/// highlight. In order to receive the selection event, the subclasses need to
/// register themselves to [SelectionRegistrar]s. Use the
/// [SelectionContainer.maybeOf] to get the the selection registrar.
abstract class Selectable {
  /// Clear the selection from the [Selectable] and remove any existing
  /// highlight as if there is no selection at all.
  void clearSelection();

  /// The bounds of this selectable related to the global coordindate.
  Rect get globalRect;

  /// Copy the data from the selectable, returning `null` if nothing is selected.
  Object? copy();

  /// Selects all the available contents in this object.
  ///
  /// This method can be called as the result of keyboard select-all, i.e.
  /// ctrl + A, or cmd + A in macOS.
  void selectAll();

  /// A selection event is sent to this object. The subclasses need to update
  /// its selection or delegate the selection event to its selectable children
  /// if there is any.
  SelectionResult dispatchSelectionEvent(SelectionEvent event);
}

/// A util class that provides useful methods for updating selections.
class SelectionUtil {
  SelectionUtil._();

  /// Determine Selection result purely on the coordinate of the target
  /// rectangle.
  ///
  /// This method only returns [SelectionResult.previous] or
  /// [SelectionResult.next]. This is useful when the drag offset is outside of
  /// the target rectangle or the target does not contain any selectable
  /// contents; therefore, the selection can't end in this [Selectable].
  static SelectionResult selectionBasedOnRect(Rect targetRect, Offset point) {
    if (point.dy < targetRect.top)
      return SelectionResult.previous;
    if (point.dy > targetRect.bottom)
      return SelectionResult.next;
    return point.dx >= targetRect.right
        ? SelectionResult.next
        : SelectionResult.previous;
  }


  /// Adjust the dragging offset based on target rect.
  ///
  /// This method moves the offsets to be within the target rect in case they are
  /// outside the rect.
  ///
  /// The logic works as the following:
  ///
  ///     Area 1
  ///
  ///            +============+ - - - - - -
  ///            | Rect       |
  ///  - - - - - +============+
  ///                              Area 2
  ///
  /// For points inside the widget:
  ///  Their effective locations are unchanged.
  ///
  /// For points in Area 1:
  ///   move them to top-left of the widget.
  ///
  /// For points in Area 2:
  ///   move them to bottom-right of the widget.
  static Offset adjustDragOffset(Rect targetRect, Offset point) {
    if (targetRect.contains(point)) {
      return point;
    }
    if (point.dy <= targetRect.top ||
        point.dy <= targetRect.bottom && point.dx <= targetRect.left) {
      // Area 1
      return targetRect.topLeft;
    } else {
      // Area 2
      return targetRect.bottomRight;
    }
  }
}

/// An abstract interface for selection events.
///
/// This should not be directly used. To handle a selection event, it should
/// be downward cast to a specific subclass.
///
/// See also:
///
/// * [DragSelectionEvent], which is the abstract subclass for all of the drag
///   related selection event.
abstract class SelectionEvent {
  const SelectionEvent._();
}

/// An abstract subclass for all of the mouse drag related selection events.
///
/// This should not be directly used. To handle a selection event, it should
/// be downward cast to a specific subclass, i.e. [DragSelectionStartEvent],
/// [DragSelectionUpdateEvent], or [DragSelectionEndEvent].
///
/// A drag selection follows the life cycle of a [DragSelectionStartEvent]
/// followed by zero or more [DragSelectionUpdateEvent], and finally
/// [DragSelectionEndEvent].
abstract class DragSelectionEvent extends SelectionEvent {
  const DragSelectionEvent._() : super._();
}

/// An event that indicates a drag selection has started.
///
/// This event is dispatched when the framework detects [DragStartDetails] in
/// [SelectionArea]'s gesture recognizer. The [offset] contains the start
/// location of the mouse drag.
class DragSelectionStartEvent extends DragSelectionEvent {
  /// Creates a drag selection start event.
  ///
  /// The [offset] contains the start location of the mouse drag.
  const DragSelectionStartEvent({required this.offset}) : super._();

  /// The start location of the drag.
  final Offset offset;

  @override
  String toString() {
    return 'DragSelectionStartEvent(offset: $offset)';
  }
}

/// An event that indicates the mouse drag has moved to a new location in a drag
/// selection.
///
/// This event is dispatched when the framework detects [DragUpdateDetails] in
/// [SelectionArea]'s gesture recognizer. The [offset] contains the new
/// location of the mouse drag.
class DragSelectionUpdateEvent extends DragSelectionEvent {
  /// Creates a drag selection update event.
  ///
  /// The [offset] contains the new location of the mouse drag.
  const DragSelectionUpdateEvent({required this.offset}) : super._();

  /// The new location of the mouse drag.
  final Offset offset;

  @override
  String toString() {
    return 'DragSelectionUpdateEvent(offset: $offset)';
  }
}

/// An event that indicates the mouse drag has ended.
///
/// This event is dispatched when the framework detects [DragEndDetails] in
/// [SelectionArea]'s gesture recognizer.
class DragSelectionEndEvent extends DragSelectionEvent {
  /// Creates a drag selection end event.
  const DragSelectionEndEvent() : super._();

  @override
  String toString() {
    return 'DragSelectionEndEvent()';
  }
}


/// An registrar that keeps track of [Selectable]s in the subtree.
///
/// A [Selectable] is only in the selection event loop if they are registered
/// with its immediate [SelectionRegistrar] in its ancestors of the widget tree.
///
/// To get the immediate [SelectionRegistrar], use
/// [SelectionContainer.maybeOf].
abstract class SelectionRegistrar {
  /// Adds the [selectable] into the registrar.
  ///
  /// A [Selectable] must register with the [SelectionRegistrar] in order to
  /// receive selection events.
  void add(Selectable selectable);

  /// Remove the [selectable] from the registrar.
  ///
  /// A [Selectable] must unregister itself if it is remove from the tree.
  void remove(Selectable selectable);
}
