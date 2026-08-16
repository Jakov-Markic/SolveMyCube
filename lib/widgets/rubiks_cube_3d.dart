import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../cube_face.dart';
import '../globals.dart';

/// Interactive 3D Rubik's cube, built from 26 individually-meshed "cubies"
/// (the fully-hidden center cubie is skipped) rather than a single imported
/// model file - each cubie is a dark plastic body plus up to 3 colored
/// sticker planes on its exposed faces. That per-cubie, per-sticker
/// structure is what a static imported 3D asset can't give you: it's what
/// will let a later change recolor individual stickers (from the app's
/// existing `[face][row][col]` color grid) and animate a single layer
/// turning, instead of only ever showing one fixed, solved-looking model.
///
/// Rendered with `three_js` (a Dart port of three.js) since it exposes a
/// real scene graph - runtime mesh/material creation and per-object
/// transforms - rather than just a glTF/OBJ viewer.
///
/// Colors are currently fixed to the app's default solved-cube palette
/// ([kFaceColors]); wiring this up to a live, paintable color grid is a
/// follow-up.
class RubiksCube3D extends StatefulWidget {
  /// Side length, in logical pixels, of the (square) render surface.
  ///
  /// `three_js` sizes its GL surface from an explicit [Size] passed at
  /// construction time, not from the Flutter constraints it's laid out
  /// with - wrapping it in a differently-sized `SizedBox`/`Container`
  /// changes how big it's *displayed*, but not the aspect ratio it was
  /// *rendered* at, which stretches the scene. So this must match whatever
  /// box the caller actually places it in.
  final double size;

  const RubiksCube3D({super.key, this.size = 320});

  @override
  State<RubiksCube3D> createState() => _RubiksCube3DState();
}

class _RubiksCube3DState extends State<RubiksCube3D> with RouteAware {
  /// Sequential index handed to `three_js` as [three.ThreeJS.renderNumber],
  /// which it uses to stagger native GL-surface creation when more than one
  /// instance exists at once - without it, two cubes created back-to-back
  /// (e.g. one on the page you navigated from, still mounted underneath)
  /// can race during setup and end up sharing/clobbering each other's
  /// render-surface size.
  static int _instanceCount = 0;

  late final three.ThreeJS _threeJs;
  late final three.OrbitControls _controls;

  /// Cube axis convention used to place stickers: U/D = +Y/-Y, F/B = +Z/-Z,
  /// R/L = +X/-X (a standard right-handed "solver's-eye" layout).
  static const double _cubieSize = 0.94;
  static const double _gap = 0.06;
  static const double _stride = _cubieSize + _gap;
  static const double _stickerMargin = 0.06;

  /// Creates the underlying [three.ThreeJS] surface; actual scene
  /// construction happens in [_setup] once it has a sized surface to render
  /// into.
  @override
  void initState() {
    super.initState();
    _threeJs = three.ThreeJS(
      onSetupComplete: () => setState(() {}),
      setup: _setup,
      size: Size(widget.size, widget.size),
      renderNumber: _instanceCount++,
      // Transparent clear color so the cube composites over whatever
      // background the page around it uses, instead of painting its own
      // opaque backdrop.
      settings: three.Settings(alpha: true, clearAlpha: 0),
    );
  }

  /// Subscribes to route visibility so rendering can pause while another
  /// page covers this one (see [didPushNext]/[didPopNext]).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      globalRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    globalRouteObserver.unsubscribe(this);
    _controls.dispose();
    _threeJs.dispose();
    super.dispose();
  }

  /// Stops this cube from rendering once a pushed route covers it - Flutter
  /// keeps covered pages mounted (not disposed), so without this, a page
  /// you navigated away from keeps driving its GL surface every frame in
  /// the background, fighting the newly-visible page's cube for the shared
  /// render-target size.
  @override
  void didPushNext() {
    _threeJs.isVisibleOnScreen = false;
  }

  /// Resumes rendering once this page is uncovered again.
  @override
  void didPopNext() {
    _threeJs.isVisibleOnScreen = true;
  }

  /// Hands the whole widget surface over to the three_js renderer.
  @override
  Widget build(BuildContext context) => _threeJs.build();

  // ---------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------

  /// Builds the camera, lighting, orbit controls, and the cube itself.
  Future<void> _setup() async {
    _threeJs.camera = three.PerspectiveCamera(
      45,
      _threeJs.width / _threeJs.height,
      0.1,
      100,
    );
    _threeJs.camera.position.setValues(4.5, 4.5, 6.5);

    _controls = three.OrbitControls(_threeJs.camera, _threeJs.globalKey);

    // No scene.background set: leaving it null lets the transparent
    // clear color (see Settings above) show through instead of painting
    // an opaque backdrop over the page behind it.
    _threeJs.scene = three.Scene();

    _threeJs.scene.add(three.AmbientLight(0xffffff, 0.6));
    final keyLight = three.DirectionalLight(0xffffff, 0.8);
    keyLight.position.setValues(5, 8, 6);
    _threeJs.scene.add(keyLight);

    _buildCube();

    _threeJs.addAnimationEvent((dt) {
      _controls.update();
    });
  }

  /// Places 26 cubies (all `[-1,0,1]^3` grid positions except the hidden
  /// center) and, for each cubie face that sits on the cube's outer
  /// boundary, a colored sticker plane facing outward.
  void _buildCube() {
    final bodyMaterial = three.MeshPhongMaterial.fromMap({
      'color': 0x0a0a0a,
      'shininess': 10,
    });
    final stickerMaterials = {
      for (final face in Face.values)
        face: three.MeshPhongMaterial.fromMap({
          'color': _toHex24(face.defaultColor),
          'shininess': 40,
        }),
    };
    final stickerSize = _cubieSize - _stickerMargin * 2;
    const stickerOffset = _cubieSize / 2 + 0.005;

    for (var xi = -1; xi <= 1; xi++) {
      final cx = xi * _stride;
      for (var yi = -1; yi <= 1; yi++) {
        final cy = yi * _stride;
        for (var zi = -1; zi <= 1; zi++) {
          final cz = zi * _stride;
          if (xi == 0 && yi == 0 && zi == 0) continue;

          final body = three.Mesh(
            three.BoxGeometry(_cubieSize, _cubieSize, _cubieSize),
            bodyMaterial,
          );
          body.position.setValues(cx, cy, cz);
          _threeJs.scene.add(body);

          if (xi == 1) {
            _addSticker(stickerMaterials[Face.R]!, stickerSize,
                cx + stickerOffset, cy, cz, rotationY: math.pi / 2);
          }
          if (xi == -1) {
            _addSticker(stickerMaterials[Face.L]!, stickerSize,
                cx - stickerOffset, cy, cz, rotationY: -math.pi / 2);
          }
          if (yi == 1) {
            _addSticker(stickerMaterials[Face.U]!, stickerSize, cx,
                cy + stickerOffset, cz, rotationX: -math.pi / 2);
          }
          if (yi == -1) {
            _addSticker(stickerMaterials[Face.D]!, stickerSize, cx,
                cy - stickerOffset, cz, rotationX: math.pi / 2);
          }
          if (zi == 1) {
            _addSticker(
                stickerMaterials[Face.F]!, stickerSize, cx, cy, cz + stickerOffset);
          }
          if (zi == -1) {
            _addSticker(stickerMaterials[Face.B]!, stickerSize, cx, cy,
                cz - stickerOffset, rotationY: math.pi);
          }
        }
      }
    }
  }

  /// Adds a single sticker plane at ([x], [y], [z]), rotated to face
  /// outward per [rotationX]/[rotationY] (see the per-face call sites in
  /// [_buildCube] for the mapping from cube face to rotation).
  void _addSticker(
    three.Material material,
    double size,
    double x,
    double y,
    double z, {
    double rotationX = 0,
    double rotationY = 0,
  }) {
    final sticker = three.Mesh(three.PlaneGeometry(size, size), material);
    sticker.position.setValues(x, y, z);
    sticker.rotation.x = rotationX;
    sticker.rotation.y = rotationY;
    _threeJs.scene.add(sticker);
  }

  /// Converts a Flutter [Color] to a 0xRRGGBB int, as most three_js
  /// material/color constructors expect.
  int _toHex24(Color color) {
    final r = (color.r * 255).round() & 0xff;
    final g = (color.g * 255).round() & 0xff;
    final b = (color.b * 255).round() & 0xff;
    return (r << 16) | (g << 8) | b;
  }
}
