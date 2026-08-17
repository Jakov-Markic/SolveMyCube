import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../cube_face.dart';
import '../globals.dart';

/// Interactive 3D Rubik's cube, built from 26 individually-meshed "cubies"
/// (the fully-hidden center cubie is skipped) rather than a single imported
/// model file - each cubie is a dark plastic body plus up to 3 colored
/// sticker planes on its exposed faces. That per-cubie, per-sticker
/// structure is what a static imported 3D asset can't give you: each
/// sticker is its own mesh with its own material, so it can be recolored
/// independently from the app's existing `[face][row][col]` color grid.
///
/// Rendered with `three_js` (a Dart port of three.js) since it exposes a
/// real scene graph - runtime mesh/material creation and per-object
/// transforms - rather than just a glTF/OBJ viewer.
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

  /// Sticker colors, indexed `[face][row][col]` - the same shape and
  /// convention used by [RubiksGridView] and [RubiksCube.grid]. A null cell
  /// renders as an "unpainted" neutral sticker; a null `faces` entirely
  /// renders the default solved-cube palette ([FaceX.defaultColor]).
  ///
  /// Read fresh every frame (not just once, or only when this widget is
  /// rebuilt) - see [_syncStickerColors] - so painting directly into a
  /// still-mounted `List` (as the manual-fill grid does) shows up without
  /// needing the caller to force a rebuild.
  final List<List<List<Color?>>>? faces;

  const RubiksCube3D({super.key, this.size = 320, this.faces});

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

  /// A neutral "unpainted sticker" color, matching the look of an empty
  /// cell in [RubiksGridView] (`surfaceContainerHighest`-ish), shown when
  /// [RubiksCube3D.faces] is provided but a specific cell is still null.
  static const int _emptyStickerHex = 0x30414c;

  late three.ThreeJS _threeJs;
  late three.OrbitControls _controls;

  /// Sticker materials, indexed `[face.index][row][col]` - one per sticker,
  /// so each of the 54 stickers can be recolored independently without
  /// rebuilding any geometry.
  late List<List<List<three.Material>>> _stickerMaterials;

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
    _threeJs = _createThreeJs();
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
  ///
  /// This used to fully dispose and recreate the render surface here
  /// instead of just resuming it, to work around a sizing glitch on
  /// return - but disposing one `ThreeJS`'s native GL/texture resources
  /// while constructing a new one raced the shared ANGLE context badly
  /// enough that a touch landing in that window (exactly what
  /// `OrbitControls` listens for) could hard-lock the native GPU thread,
  /// freezing the whole device. A mis-sized cube is a cosmetic problem;
  /// that isn't, so this goes back to the simple resume until there's a
  /// safer fix for the sizing glitch.
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

  three.ThreeJS _createThreeJs() {
    return three.ThreeJS(
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
      _syncStickerColors();
    });
  }

  /// Places 26 cubies (all `[-1,0,1]^3` grid positions except the hidden
  /// center) and, for each cubie face that sits on the cube's outer
  /// boundary, a colored sticker plane facing outward.
  ///
  /// Each sticker's `(row, col)` on its face is derived directly from the
  /// cubie's grid position - e.g. the F face has zi=1 fixed, and its
  /// in-plane axes (xi, yi) map to (col, row) via `col = xi + 1`,
  /// `row = 1 - yi` (yi=1, the top row in world space, is row 0). The
  /// mapping differs per face (see the per-face branches below) but always
  /// puts the center cubie (the varying axes both 0) at (row 1, col 1),
  /// matching [RubiksCube3D.faces]'s `[face][row][col]` convention.
  void _buildCube() {
    final bodyMaterial = three.MeshPhongMaterial.fromMap({
      'color': 0x0a0a0a,
      'shininess': 10,
    });
    _stickerMaterials = [
      for (final face in Face.values)
        [
          for (var row = 0; row < 3; row++)
            [
              for (var col = 0; col < 3; col++)
                three.MeshPhongMaterial.fromMap({
                  'color': _hexFor(face, row, col),
                  'shininess': 40,
                }),
            ],
        ],
    ];
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
            _addSticker(
                _stickerMaterials[Face.R.index][1 - yi][1 - zi],
                stickerSize,
                cx + stickerOffset,
                cy,
                cz,
                rotationY: math.pi / 2);
          }
          if (xi == -1) {
            _addSticker(
                _stickerMaterials[Face.L.index][1 - yi][zi + 1],
                stickerSize,
                cx - stickerOffset,
                cy,
                cz,
                rotationY: -math.pi / 2);
          }
          if (yi == 1) {
            _addSticker(
                _stickerMaterials[Face.U.index][zi + 1][xi + 1],
                stickerSize,
                cx,
                cy + stickerOffset,
                cz,
                rotationX: -math.pi / 2);
          }
          if (yi == -1) {
            _addSticker(
                _stickerMaterials[Face.D.index][1 - zi][xi + 1],
                stickerSize,
                cx,
                cy - stickerOffset,
                cz,
                rotationX: math.pi / 2);
          }
          if (zi == 1) {
            _addSticker(_stickerMaterials[Face.F.index][1 - yi][xi + 1],
                stickerSize, cx, cy, cz + stickerOffset);
          }
          if (zi == -1) {
            _addSticker(
                _stickerMaterials[Face.B.index][1 - yi][1 - xi],
                stickerSize,
                cx,
                cy,
                cz - stickerOffset,
                rotationY: math.pi);
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

  /// Re-reads [RubiksCube3D.faces] and pushes any changed sticker colors
  /// into their materials. Runs once per frame (see [_setup]) rather than
  /// only on prop changes, since [RubiksCube3D.faces] is typically the same
  /// long-lived `List` the caller paints into in place (e.g. manual fill),
  /// not a freshly-allocated one each time - a `didUpdateWidget` reference
  /// check wouldn't see those in-place edits at all.
  void _syncStickerColors() {
    for (final face in Face.values) {
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 3; col++) {
          _stickerMaterials[face.index][row][col]
              .color
              .setFromHex32(_hexFor(face, row, col));
        }
      }
    }
  }

  /// Resolves the sticker color for `(face, row, col)`: [RubiksCube3D.faces]
  /// when given (falling back to [_emptyStickerHex] for a still-null cell),
  /// otherwise the default solved-cube color for that face.
  int _hexFor(Face face, int row, int col) {
    final faces = widget.faces;
    if (faces == null) return _toHex24(face.defaultColor);
    final color = faces[face.index][row][col];
    return color != null ? _toHex24(color) : _emptyStickerHex;
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
