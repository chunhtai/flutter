// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'label_and_value.dart';
import 'semantics.dart';

/// Indicates a table element.
///
/// Uses aria table role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticTable extends SemanticRole {
  SemanticTable(SemanticsObject semanticsObject)
    : super(EngineSemanticsRole.table, semanticsObject) {
    setAriaRole('table');
  }

  @override
  void setBehaviors() {
    withBasicsBehaviors(preferredLabelRepresentation: LabelRepresentation.ariaLabel);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a table cell element.
///
/// Uses aria cell role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticCell extends SemanticRole {
  SemanticCell(SemanticsObject semanticsObject)
    : super(EngineSemanticsRole.cell, semanticsObject) {
    setAriaRole('cell');
  }

  @override
  void setBehaviors() {
    withBasicsBehaviors(
      // Prefer sized span because if this is a leaf with aria-label the label
      // will be ignored, Dom text can focus on the text but the rect is wrong.
      // Sized span works best.
      preferredLabelRepresentation: LabelRepresentation.sizedSpan,
    );
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a table row element.
///
/// Uses aria row role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticRow extends SemanticRole {
  SemanticRow(SemanticsObject semanticsObject)
    : super(EngineSemanticsRole.row, semanticsObject) {
    setAriaRole('row');
  }

  @override
  void setBehaviors() {
    withBasicsBehaviors(preferredLabelRepresentation: LabelRepresentation.ariaLabel);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates a table column header element.
///
/// Uses aria columnheader role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticColumnHeader extends SemanticRole {
  SemanticColumnHeader(SemanticsObject semanticsObject)
    : super(EngineSemanticsRole.columnHeader, semanticsObject) {
    setAriaRole('columnheader');
  }

  @override
  void setBehaviors() {
    withBasicsBehaviors(preferredLabelRepresentation: LabelRepresentation.ariaLabel);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
