import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../cube_face.dart';
import '../globals.dart';

/// Interactive 3D Rubik's cube
class RubiksCube3D extends StatefulWidget {
  /// Side length, in logical pixels, of the (square) render surface.
  final double size;
  final List<List<List<Color?>>>? faces;

  const RubiksCube3D({super.key, this.size = 320, this.faces});

  @override
  State<RubiksCube3D> createState() => _RubiksCube3DState();
}

class _RubiksCube3DState extends State<RubiksCube3D> with RouteAware {
  /// Default hex value for sticker with no color
  static const int _emptyStickerHex = 0x30414c;

  /// Serializes native GL create/dispose across all instances - two alive
  /// at once previously raced the shared context and could freeze the GPU.
  static Future<void> _gpuQueue = Future.value();

  static void _enqueue(FutureOr<void> Function() action) {
    _gpuQueue = _gpuQueue.then((_) => action()).catchError((_) {});
  }

  three.ThreeJS? _threeJs;
  three.OrbitControls? _controls;

  /// Materials for each sticker
  late List<List<List<three.Material>>> _stickerMaterials;

  /// Parameters for the cubies and stickers, in world-space units
  static const double _cubieSize = 0.94;
  static const double _gap = 0.06;
  static const double _stride = _cubieSize + _gap;
  static const double _stickerMargin = 0.06;

  @override
  void initState() {
    super.initState();
    _scheduleConstruct();
  }

  /// Subscribes to route visibility so rendering can pause while another page covers this one
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
    _scheduleDispose(rebuild: false);
    super.dispose();
  }

  /// Fully tears down the native context once covered, instead of just pausing.
  @override
  void didPushNext() {
    _threeJs?.isVisibleOnScreen = false;
    _scheduleDispose(rebuild: true);
  }

  /// Constructs a fresh instance so it can never inherit a stale/shrunk size.
  @override
  void didPopNext() {
    _scheduleConstruct();
  }

  void _scheduleConstruct() {
    _enqueue(() async {
      if (!mounted) return;
      final completer = Completer<void>();
      final threeJs = _createThreeJs(onReady: () => completer.complete());
      setState(() => _threeJs = threeJs);
      await completer.future;
    });
  }

  void _scheduleDispose({required bool rebuild}) {
    final threeJs = _threeJs;
    final controls = _controls;
    if (threeJs == null) return;
    _threeJs = null;
    _controls = null;
    if (rebuild && mounted) setState(() {});
    _enqueue(() {
      controls?.dispose();
      threeJs.dispose();
    });
  }

  /// The three_js surface, or a same-sized placeholder mid construct/dispose.
  @override
  Widget build(BuildContext context) {
    final threeJs = _threeJs;
    return threeJs == null
        ? SizedBox(width: widget.size, height: widget.size)
        : threeJs.build();
  }

  three.ThreeJS _createThreeJs({required VoidCallback onReady}) {
    return three.ThreeJS(
      onSetupComplete: () {
        onReady();
        if (mounted) setState(() {});
      },
      setup: _setup,
      size: Size(widget.size, widget.size),
      // The GPU queue above already prevents concurrent init, no stagger needed.
      renderNumber: 0,
      // Transparent color
      settings: three.Settings(alpha: true, clearAlpha: 0),
    );
  }

  /// Builds the camera, lighting, orbit controls, and the cube itself.
  Future<void> _setup() async {
    final threeJs = _threeJs!;
    threeJs.camera = three.PerspectiveCamera(
      45,
      threeJs.width / threeJs.height,
      0.1,
      100,
    );
    threeJs.camera.position.setValues(4.5, 4.5, 6.5);

    _controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    threeJs.scene = three.Scene();

    threeJs.scene.add(three.AmbientLight(0xffffff, 0.6));
    final keyLight = three.DirectionalLight(0xffffff, 0.8);
    keyLight.position.setValues(5, 8, 6);
    threeJs.scene.add(keyLight);

    _buildCube(threeJs);

    threeJs.addAnimationEvent((dt) {
      _controls?.update();
      _syncStickerColors();
    });
  }

  /// Places 26 cubies (all `[-1,0,1]^3` grid positions except the hidden
  /// center) and, for each cubie face that sits on the cube's outer
  /// boundary, a colored sticker plane facing outward.
  void _buildCube(three.ThreeJS threeJs) {
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
          threeJs.scene.add(body);

          if (xi == 1) {
            _addSticker(
                threeJs,
                _stickerMaterials[Face.R.index][1 - yi][1 - zi],
                stickerSize,
                cx + stickerOffset,
                cy,
                cz,
                rotationY: math.pi / 2);
          }
          if (xi == -1) {
            _addSticker(
                threeJs,
                _stickerMaterials[Face.L.index][1 - yi][zi + 1],
                stickerSize,
                cx - stickerOffset,
                cy,
                cz,
                rotationY: -math.pi / 2);
          }
          if (yi == 1) {
            _addSticker(
                threeJs,
                _stickerMaterials[Face.U.index][zi + 1][xi + 1],
                stickerSize,
                cx,
                cy + stickerOffset,
                cz,
                rotationX: -math.pi / 2);
          }
          if (yi == -1) {
            _addSticker(
                threeJs,
                _stickerMaterials[Face.D.index][1 - zi][xi + 1],
                stickerSize,
                cx,
                cy - stickerOffset,
                cz,
                rotationX: math.pi / 2);
          }
          if (zi == 1) {
            _addSticker(
                threeJs,
                _stickerMaterials[Face.F.index][1 - yi][xi + 1],
                stickerSize,
                cx,
                cy,
                cz + stickerOffset);
          }
          if (zi == -1) {
            _addSticker(
                threeJs,
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

  /// Adds a single sticker plane at ([x], [y], [z]), rotated to face x and y rotation
  void _addSticker(
    three.ThreeJS threeJs,
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
    threeJs.scene.add(sticker);
  }

  /// Updates all sticker colors
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

  /// Convert all colors (face, row, col) to hex
  int _hexFor(Face face, int row, int col) {
    final faces = widget.faces;
    if (faces == null) return _toHex24(face.defaultColor);
    final color = faces[face.index][row][col];
    return color != null ? _toHex24(color) : _emptyStickerHex;
  }

  /// Convert Color to 24-bit hex (0xRRGGBB)
  int _toHex24(Color color) {
    final r = (color.r * 255).round() & 0xff;
    final g = (color.g * 255).round() & 0xff;
    final b = (color.b * 255).round() & 0xff;
    return (r << 16) | (g << 8) | b;
  }
}
