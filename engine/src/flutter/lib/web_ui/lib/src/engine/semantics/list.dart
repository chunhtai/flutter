// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'label_and_value.dart';
import 'semantics.dart';

/// Indicates a list container.
///
/// Uses aria list role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticList extends SemanticRole {
  SemanticList(SemanticsObject semanticsObject)
    : super(EngineSemanticsRole.list, semanticsObject) {
    setAriaRole('list');
  }

  @override
  void setBehaviors() {
    withBasicsBehaviors(preferredLabelRepresentation: LabelRepresentation.ariaLabel);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

/// Indicates an item in a list.
///
/// Uses aria listitem role to convey this semantic information to the element.
///
/// Screen-readers take advantage of "aria-label" to describe the visual.
class SemanticListItem extends SemanticRole {
  SemanticListItem(SemanticsObject semanticsObject)
    : super(EngineSemanticsRole.listItem, semanticsObject) {
    setAriaRole('listitem');
  }

  @override
  void setBehaviors() {
    withBasicsBehaviors(preferredLabelRepresentation: LabelRepresentation.ariaLabel);
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
