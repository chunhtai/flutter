// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';


import 'actions.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'shortcuts.dart';

/// A widget that introduces an area that allows for selection for the subtree.
///
/// To exclude widgets from this selection area, wrap its subtree using
/// [SelectionContainer] with enabled = false.
///
/// You can also wraps part of the subtree with another [SelectionArea] to
/// create a separate selection system from its parent [SelectionArea]. The
/// selection of the child [SelectionArea] can not extend pass its subtree, and
/// the selection of the parent [SelectionArea] can not extend inside the child
/// [SelectionArea].
class SelectionArea extends StatefulWidget {
  /// Create a new [SelectionArea] widget.
  ///
  /// To disable text selection for a part of the widget hierarchy, wrap them
  /// in a [SelectionContainer] with [SelectionContainer.enabled] set to
  /// false`.
  const SelectionArea({
    required this.child,
    Key? key,
  }) : super(key: key);

  /// The child widget this selection area applies to.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<SelectionArea> createState() => _SelectionAreaState();
}

class _SelectionAreaState extends State<SelectionArea> {
  static const Map<ShortcutActivator, Intent> _kMacShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyC, meta: true) : _CopyIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, meta: true) : _SelectAllIntent(),
  };

  static const Map<ShortcutActivator, Intent> _kWindowsShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyC, control: true) : _CopyIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true) : _SelectAllIntent(),
  };

  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    _CopyIntent: CallbackAction<_CopyIntent>(onInvoke: _copy),
    _SelectAllIntent: CallbackAction<_SelectAllIntent>(onInvoke: _selectAll),
  };

  final Map<Type, GestureRecognizerFactory> _gestureRecognizers = <Type, GestureRecognizerFactory>{};

  final StaticMultiSelectableSelectionUpdater _selectionUpdater = StaticMultiSelectableSelectionUpdater();
  Offset? _currentDragPosition;
  bool get _dragInProgress => _currentDragPosition != null;
  bool _scheduledSelectionUpdate = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _gestureRecognizers[PanGestureRecognizer] = GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(supportedDevices: <PointerDeviceKind>{PointerDeviceKind.mouse}),
          (PanGestureRecognizer instance) {
        instance
          ..onDown = _handleDragDown
          ..onStart = _handleDragStart
          ..onUpdate = _handleDragUpdate
          ..onEnd = _handleDragEnd
          ..onCancel = _cancelSelection
          ..dragStartBehavior = DragStartBehavior.down;
      },
    );
    _gestureRecognizers[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(debugOwner: this, supportedDevices: <PointerDeviceKind>{PointerDeviceKind.mouse}),
          (TapGestureRecognizer instance) {
        instance.onTap = _cancelSelection;
      },
    );
    _focusNode = FocusNode();
  }

  void _handleDragDown(DragDownDetails details) {
    _focusNode.requestFocus();
    _cancelSelection();
  }

  void _handleDragStart(DragStartDetails details) {
    final Offset offset = (context.findRenderObject() as RenderBox?)!.localToGlobal(details.localPosition);
    _currentDragPosition = offset;
    _selectionUpdater.dispatchSelectionEvent(DragSelectionStartEvent(offset: offset));
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(_dragInProgress);
    final Offset offset = (context.findRenderObject() as RenderBox?)!.localToGlobal(details.localPosition);
    if (_currentDragPosition != offset) {
      _currentDragPosition = offset;
      _updateDragSelection();
    }
  }

  void _handleDragEnd(DragEndDetails details) => _endDragSelection();

  void _updateDragSelection() {
    // This method can be called when the drag is not in progress. This can
    // happen if the the child scrollable returns SelectionResult.pending, and
    // the selection area scheduled a selection update for the next frame, but
    // the drag is lifted before the scheduled selection update is run.
    if (_scheduledSelectionUpdate || !_dragInProgress)
      return;
    if (_selectionUpdater.dispatchSelectionEvent(DragSelectionUpdateEvent(offset: _currentDragPosition!)) == SelectionResult.pending) {
      _scheduledSelectionUpdate = true;
      SchedulerBinding.instance!.addPostFrameCallback((Duration timeStamp) {
        _scheduledSelectionUpdate = false;
        _updateDragSelection();
      });
      return;
    }
  }

  void _endDragSelection() {
    _currentDragPosition = null;
    _scheduledSelectionUpdate = false;
    _selectionUpdater.dispatchSelectionEvent(const DragSelectionEndEvent());
  }

  void _cancelSelection() {
    _endDragSelection();
    _selectionUpdater.clear();
  }

  void _selectAll(Intent intent) {
    _cancelSelection();
    _selectionUpdater.selectAll();
  }

  Future<void> _copy(Intent intent) async {
    final Object? data = _selectionUpdater.copy();
    if (data == null) {
      return;
    }
    Clipboard.setData(ClipboardData(text: data as String));
  }

  void _handleSelectablesChanged(List<Selectable> selectables) {
    _selectionUpdater.updateSelectables(selectables);
  }

  @override
  void dispose() {
    _selectionUpdater.clear();
    _focusNode.dispose();
    super.dispose();
  }

  Map<ShortcutActivator, Intent> _getPlatformShortcuts() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return _kWindowsShortcuts;

      case TargetPlatform.macOS:
        return _kMacShortcuts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      debugLabel: 'Selection Area shortcuts',
      shortcuts: _getPlatformShortcuts(),
      child: Actions(
        actions: _actions,
        child: Focus(
          focusNode: _focusNode,
          child: RawGestureDetector(
            gestures: _gestureRecognizers,
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            child: SelectionContainer(
              enabled: true,
              onSelectablesChange: _handleSelectablesChanged,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}

class _CopyIntent extends Intent {
  const _CopyIntent();
}

/// An abstract base class for updating multiple selectable children.
///
/// This class optimize the selection update by keeping track the current
/// selectable that contains the selection edge.
abstract class MultiSelectableSelectionUpdaterBase {

  /// Gets the list selectables this updater is responsible for updating.
  ///
  /// The subclasses is responsible for updating the selection when the
  /// selectables in the list has changed.
  List<Selectable> get selectables;

  /// The current selectable that contains the selection edge.
  @protected
  int currentSelectionIndex = -1;

  /// Removes the selection of all the selectables this updater managed.
  void clear() {
    for (final Selectable selectable in selectables) {
      selectable.clearSelection();
    }
    currentSelectionIndex = -1;
  }

  /// Copies the selected contents of all the selectables.
  Object? copy() {
    final List<Object> selections = <Object>[];
    for (final Selectable selectable in selectables) {
      final Object? data = selectable.copy();
      if (data != null)
        selections.add(data);
    }
    if (selections.isEmpty)
      return null;
    return selections.join('\n');
  }

  /// Selects all of the contents of all of the selectables.
  void selectAll() {
    for (final Selectable selectable in selectables) {
      selectable.selectAll();
    }
    currentSelectionIndex = selectables.length - 1;
  }

  /// Dispatch the selection event to all of its selectable children.
  /// This may return none for DragSelectionUpdateEvent if there is no
  /// selectable child.
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    if (event is! DragSelectionEvent) {
      throw UnimplementedError('only support drag selection');
    }
    if (event is DragSelectionUpdateEvent) {
      return currentSelectionIndex == -1 ? _initSelection(event) : _adjustSelection(event);
    }
    if (event is DragSelectionStartEvent || event is DragSelectionEndEvent) {
      for (final Selectable selectable in selectables) {
        dispatchSelectionEventToChild(selectable, event);
      }
    }
    return SelectionResult.none;
  }

  /// Dispatches a selection event to a specific selectable.
  ///
  /// Override this method if it requires to generate additional events or
  /// treatments prior to sending the selection event.
  @protected
  SelectionResult dispatchSelectionEventToChild(Selectable selectable, SelectionEvent event) {
    return selectable.dispatchSelectionEvent(event);
  }

  /// Initialize the selection of the selectable children.
  ///
  /// The goal is to find which selectable child the selection starts on
  /// Returns [SelectionResult.end] if the selection edge ends on any of the
  /// children. Otherwise, it returns [SelectionResult.previous] if the selection
  /// should start before all of its children. Returns [SelectionResult.next]
  /// if the selection should start after all of its children.
  SelectionResult _initSelection(DragSelectionUpdateEvent event) {
    for (int index = 0; index < selectables.length; index += 1){
      final Selectable child =  selectables[index];
      switch (dispatchSelectionEventToChild(child, event)) {
        case SelectionResult.next:
          currentSelectionIndex = index;
          break;
        case SelectionResult.end:
          currentSelectionIndex = index;
          return SelectionResult.end;
        case SelectionResult.previous:
          if (index == 0) {
            currentSelectionIndex = 0;
            return SelectionResult.previous;
          }
          return SelectionResult.end;
        case SelectionResult.pending:
          currentSelectionIndex = index;
          return SelectionResult.pending;
        case SelectionResult.none:
          assert(false);
      }
    }
    if (currentSelectionIndex == -1) {
      assert(selectables.isEmpty);
      return SelectionResult.none;
    }
    return SelectionResult.next;
  }

  /// Adjust the selection based on the drag selection update event if there
  /// is already a selectable child that contains the selection edge.
  ///
  /// This method starts by sending the selection event to the current
  /// selectable that contains the selection edge, and finds forward or backward
  /// if that selectable no longer contains the selection edge.
  SelectionResult _adjustSelection(DragSelectionUpdateEvent event) {
    assert(currentSelectionIndex != -1);
    late SelectionResult result;
    while (currentSelectionIndex < selectables.length &&
        currentSelectionIndex >= 0) {
      result = dispatchSelectionEventToChild(selectables[currentSelectionIndex], event);
      switch (result) {
        case SelectionResult.end:
        case SelectionResult.pending:
          return result;
        case SelectionResult.next:
          if (currentSelectionIndex == selectables.length -1) {
            return result;
          }
          currentSelectionIndex += 1;
          result = dispatchSelectionEventToChild(selectables[currentSelectionIndex], event);
          if (result == SelectionResult.end ||
              result == SelectionResult.pending) {
            return result;
          }
          if (result == SelectionResult.previous) {
            currentSelectionIndex -= 1;
            return SelectionResult.end;
          }
          break;
        case SelectionResult.previous:
          if (currentSelectionIndex == 0) {
            return result;
          }
          currentSelectionIndex -= 1;
          result = dispatchSelectionEventToChild(selectables[currentSelectionIndex], event);
          if (result == SelectionResult.end ||
              result == SelectionResult.pending) {
            return result;
          }
          if (result == SelectionResult.next) {
            currentSelectionIndex += 1;
            return SelectionResult.end;
          }
          break;
        case SelectionResult.none:
          // DragSelectionUpdate should never return none.
          assert(false);
          return SelectionResult.none;
      }
    }
    return result;
  }
}

/// A selection updater that assumes the selectable child changes infrequently
/// and without a specific rule.
///
/// The updater reset the selection every time a new selectable has been added
/// or removed from the selectables.
class StaticMultiSelectableSelectionUpdater extends MultiSelectableSelectionUpdaterBase {
  @override
  List<Selectable> get selectables => _selectables;
  List<Selectable> _selectables = const <Selectable>[];

  DragSelectionStartEvent? _currentDragStart;

  /// Updates the selectables this updater manages.
  ///
  /// This method will reset the ongoing selection.
  void updateSelectables(List<Selectable> other) {
    if (_selectables == other) {
      return;
    }
    if (!listEquals<Selectable>(_selectables, other)) {
      // Make sure the existing selectable finishes the drag selection
      if (_currentDragStart != null) {
        for (final Selectable selectable in _selectables) {
          dispatchSelectionEventToChild(selectable, const DragSelectionEndEvent());
        }
      }
      clear();
      if (_currentDragStart != null) {
        for (final Selectable selectable in _selectables) {
          dispatchSelectionEventToChild(selectable, _currentDragStart!);
        }
      }
    }
    _selectables = other;
  }

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    if (event is DragSelectionStartEvent) {
      _currentDragStart = event;
    } else if (event is DragSelectionEndEvent) {
      _currentDragStart = null;
    }
    return super.dispatchSelectionEvent(event);
  }

}

/// A container that collects the [Selectable]s in the subtree.
///
/// This widget creates its own [SelectionContainer] to collect the
/// selectables in the subtree. These selectables are not visible to any other
/// [SelectionContainer] above this widget. The creator of this widget
/// can extract the selectables this container collected using the
/// [onSelectablesChange] callback and is responsible for the selection update
/// of the collected selectables.
///
/// If the [enabled] is false, this container does not collect selectables in
/// the subtree, it will also hide them from other [SelectionContainer]
/// above this widget.
class SelectionContainer extends StatefulWidget {
  /// creates a selection container to collect the [Selectable]s in the subtree.
  ///
  /// If the [enabled] is true, the [onSelectablesChange] must not be null.
  const SelectionContainer({
    Key? key,
    required this.enabled,
    this.onSelectablesChange,
    required this.child
  }) : assert(!enabled || onSelectablesChange != null),
       super(key: key);

  /// Whether this selection container is enabled.
  ///
  /// If this property is set to false, this container not only ignores all of
  /// the selectables in the subtree, but it also hides them from any other
  /// [SelectionContainer] above this widget.
  final bool enabled;

  /// The child widget this selection container contains.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Called when the selectables this widget collected has changed.
  ///
  /// Use this method to extract the collected selectables in the subtree.
  final ValueChanged<List<Selectable>>? onSelectablesChange;

  /// Gets the immediate ancestor [SelectionRegistrar] of the [BuildContext].
  ///
  /// If this returns null, either there is no [SelectionContainer] above the
  /// [BuildContext] or the immediate [SelectionContainer] is not enabled.
  static SelectionRegistrar? maybeOf(BuildContext context) {
    final _SelectionRegistrarScope? scope = context.dependOnInheritedWidgetOfExactType<_SelectionRegistrarScope>();
    if (scope?.enabled != true) {
      return null;
    }
    return scope?.registrar;
  }

  @override
  State<SelectionContainer> createState() => _SelectionContainerState();
}

class _SelectionContainerState extends State<SelectionContainer> implements SelectionRegistrar {
  /// Registered selectable in screen order.
  List<Selectable> get _selectables {
    if(_isCachedSelectablesDirty) {
      _calculateChildrenSelectionOrder();
    }
    assert(!_isCachedSelectablesDirty);
    return _cachedSelectables;
  }
  bool _isCachedSelectablesDirty = true;
  List<Selectable> _cachedSelectables = const <Selectable>[];
  final Set<Selectable> _registeredSelectables = <Selectable>{};

  void _calculateChildrenSelectionOrder() {
    _cachedSelectables = _registeredSelectables.toList();

    _cachedSelectables.sort((Selectable a, Selectable b) {
      final Rect rectA = a.globalRect;
      final Rect rectB = b.globalRect;
      if (rectA.bottomRight.dy != rectB.bottomRight.dy)
        return (rectA.bottomRight.dy - rectB.bottomRight.dy).truncate();
      return (rectA.bottomRight.dx - rectB.bottomRight.dx).truncate();
    });
    _isCachedSelectablesDirty = false;
  }

  @override
  void dispose() {
    for (final Selectable selectable in _registeredSelectables) {
      selectable.clearSelection();
    }
    _registeredSelectables.clear();
    _isCachedSelectablesDirty = true;
    super.dispose();
  }

  bool _notifyScheduled = false;

  void _scheduleNotifyListenerIfNeeded() {
    if (_notifyScheduled)
      return;
    _notifyScheduled = true;
    // We can't notify right away because the Selectables are added during the
    // build phase and they can't handle selection event until they are laid out
    // because they don't have size yet.
    SchedulerBinding.instance!.addPostFrameCallback((Duration timeStamp) {
      _notifyScheduled = false;
      widget.onSelectablesChange!(_selectables);
    });
  }

  @override
  void add(Selectable selectable) {
    if (_registeredSelectables.contains(selectable))
      return;
    _registeredSelectables.add(selectable);
    _isCachedSelectablesDirty = true;
    _scheduleNotifyListenerIfNeeded();
  }

  @override
  void remove(Selectable selectable) {
    _registeredSelectables.remove(selectable);
    selectable.clearSelection();
    _scheduleNotifyListenerIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return _SelectionRegistrarScope(
      registrar: this,
      enabled: widget.enabled,
      child: widget.child,
    );
  }
}

class _SelectionRegistrarScope extends InheritedWidget {
  const _SelectionRegistrarScope({
    Key? key,
    required this.registrar,
    required this.enabled,
    required Widget child,
  }) : super(key: key, child: child);

  /// The registrar.
  final SelectionRegistrar registrar;

  /// whether this enabled
  final bool enabled;

  @override
  bool updateShouldNotify(_SelectionRegistrarScope oldWidget) {
    return oldWidget.registrar != registrar ||
           oldWidget.enabled != enabled;
  }
}
