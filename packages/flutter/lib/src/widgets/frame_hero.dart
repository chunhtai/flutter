// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

typedef AnimationWidgetBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Rect origin,
  Rect destination,
);

class FrameHeroManager extends StatefulWidget {
  const FrameHeroManager({
    super.key,
    required this.child,
  });

  final Widget child;

  static _FrameHeroManagerState _of(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_FrameHeroManagerScope>()!.state;
  }

  @override
  State<FrameHeroManager> createState() => _FrameHeroManagerState();
}

class _FrameHeroManagerState extends State<FrameHeroManager> {
  final Map<Object, _HeroState> _heroStates = <Object, _HeroState>{};
  // Creation/Removal aggregated during a draw frame to be process at the end
  // of frame.
  //
  // They can't be process immediate since a hero with the same tag can be
  // remove, create, or update multiple times in any orders.
  final Set<_RenderFrameHero> _pendingHeroRemovals = <_RenderFrameHero>{};
  final Set<_RenderFrameHero> _pendingAdditions = <_RenderFrameHero>{};
  final Map<Object, _FlightManifest> _flights = <Object, _FlightManifest>{};

  void createNewHero(_RenderFrameHero renderHero) {
    if (_pendingHeroRemovals.remove(renderHero)) {
      return;
    }
    _pendingAdditions.add(renderHero);
  }

  void updateExistingHero(_RenderFrameHero renderHero) {
    if (_pendingAdditions.contains(renderHero)) {
      // the location is updated after flushHeroUpdates.
      return;
    }
    assert(!_pendingHeroRemovals.contains(renderHero));
    FrameHero
  }

  void removeExistingHero(_RenderFrameHero renderHero) {
    _pendingHeroRemovals.remove(renderHero);
  }

  void _flushHeroUpdates() {

  }

  Widget _buildFlight(MapEntry<Object, _FlightManifest> entry) {
    return _HeroFlight(
      key: ValueKey<Object>(entry.key),
      manifest: entry.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _FrameHeroManagerScope(state: this, child: widget.child),
        ..._flights.entries.map<Widget>(_buildFlight),
      ],
    );
  }
}


class _FrameHeroManagerScope extends InheritedWidget {
  const _FrameHeroManagerScope({
    required this.state,
    required super.child,
  });
  final _FrameHeroManagerState state;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class _HeroState {
  _HeroState(this.iteration, this.location);
  Object? iteration;
  Offset location;
}

class _FlightManifest {
  _FlightManifest(
    this.flyBuilder,
    this.animation,
    this.rectTween,
  );
  final AnimationWidgetBuilder flyBuilder;
  final Animation<double> animation;
  final RectTween rectTween;
}

class _HeroFlight extends StatefulWidget {
  const _HeroFlight({
    required super.key,
    required this.manifest,
  });

  final _FlightManifest manifest;
  @override
  _HeroFlightState createState() => _HeroFlightState();
}

class _HeroFlightState extends State<_HeroFlight> {
  @override
  void initState() {
    super.initState();
    _animation = widget.manifest.animation;
  }



  late Animation<double> _animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        final Rect rect = widget.manifest.rectTween.lerp(_animation.value)!;
        return Positioned.fromRect(
          rect: rect,
          child: child!,
        );
      },
      child: widget.manifest.flyBuilder(
        context,
      ),
    );
  }

}

class FrameHero extends SingleChildRenderObjectWidget {
  /// Create a hero.
  ///
  /// The [tag] and [child] parameters must not be null.
  /// The [child] parameter and all of the its descendants must not be [Hero]es.
  const FrameHero({
    super.key,
    required this.tag,
    // this.createRectTween,
    // this.flightShuttleBuilder,
    // this.placeholderBuilder,
    // this.transitionOnUserGestures = false,
    required super.child,
  });

  /// The identifier for this particular hero. If the tag of this hero matches
  /// the tag of a hero on a [PageRoute] that we're navigating to or from, then
  /// a hero animation will be triggered.
  final Object tag;

  @override
  RenderObject createRenderObject(BuildContext context) {
    // TODO: implement createRenderObject
    throw UnimplementedError();
  }

}

class _RenderFrameHero extends RenderProxyBox {

}