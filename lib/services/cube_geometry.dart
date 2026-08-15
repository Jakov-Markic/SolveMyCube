import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'detector_service.dart';

/// One of the 8 detected cube corners, in pixel space, ready for drawing.
class CubeVertex {
  final int index;
  final Offset position;
  final bool visible;
  final double score;

  const CubeVertex({
    required this.index,
    required this.position,
    required this.visible,
    required this.score,
  });
}

class CubeGeometryResult {
  final List<Offset> outline;
  final List<Offset> samplePoints;
  final Rect? bounds;

  /// All 8 corners (front TL,TR,BR,BL then back TL,TR,BR,BL - same order as
  /// RubikDetector's keypoints/object points), empty when not pose-derived.
  final List<CubeVertex> cubeVertices;

  const CubeGeometryResult({
    required this.outline,
    required this.samplePoints,
    required this.bounds,
    this.cubeVertices = const <CubeVertex>[],
  });

  bool get hasOutline => outline.length >= 4;

  /// Edges of a cube wireframe, indices into [cubeVertices]: front face,
  /// back face, then the 4 edges connecting front to back corners.
  static const List<List<int>> wireframeEdges = [
    [0, 1], [1, 2], [2, 3], [3, 0],
    [4, 5], [5, 6], [6, 7], [7, 4],
    [0, 4], [1, 5], [2, 6], [3, 7],
  ];

  String get summary {
    final boundsText = bounds == null
        ? 'no bounds'
        : 'bounds=${bounds!.left.toStringAsFixed(0)},${bounds!.top.toStringAsFixed(0)} '
              '${bounds!.width.toStringAsFixed(0)}x${bounds!.height.toStringAsFixed(0)}';
    final visibleVertices = cubeVertices.where((v) => v.visible).length;
    return 'outline=${outline.length} samplePoints=${samplePoints.length} '
        'corners=$visibleVertices/8 $boundsText';
  }
}

class CubeGeometry {
  static CubeGeometryResult fromPoseResult(
    CubePoseResult pose, {
    Size? imageSize,
    int gridSize = 3,
  }) {
    final scaleX = imageSize?.width ?? 1.0;
    final scaleY = imageSize?.height ?? 1.0;

    List<Offset> toPixel(List<Offset> normalized) {
      return normalized
          .map((p) => Offset(p.dx * scaleX, p.dy * scaleY))
          .toList(growable: false);
    }

    final visible = pose.visibleKeypointsNormalized;
    final roiOutline = _rectToOutline(
      Rect.fromLTWH(
        pose.roiNormalized.left * scaleX,
        pose.roiNormalized.top * scaleY,
        pose.roiNormalized.width * scaleX,
        pose.roiNormalized.height * scaleY,
      ),
    );

    List<Offset> outline;
    if (pose.frontFaceQuadNormalized.length >= 4) {
      outline = toPixel(pose.frontFaceQuadNormalized.take(4).toList());
    } else if (visible.length >= 4) {
      outline = _axisAlignedRectangle(toPixel(visible));
    } else {
      outline = roiOutline;
    }

    final area = _polygonAreaAbs(outline);
    if (outline.length < 4 || area < 20.0) {
      outline = roiOutline;
    }

    final samplePoints = outline.length == 4
        ? _buildGridPoints(outline, gridSize)
        : const <Offset>[];

    final bounds = pose.roiNormalized.isEmpty
        ? null
        : Rect.fromLTWH(
            pose.roiNormalized.left * scaleX,
            pose.roiNormalized.top * scaleY,
            pose.roiNormalized.width * scaleX,
            pose.roiNormalized.height * scaleY,
          );

    final cubeVertices = pose.keypoints
        .map(
          (k) => CubeVertex(
            index: k.index,
            position: Offset(k.normalized.dx * scaleX, k.normalized.dy * scaleY),
            visible: k.visible,
            score: k.score,
          ),
        )
        .toList(growable: false);

    return CubeGeometryResult(
      outline: outline,
      samplePoints: samplePoints,
      bounds: bounds,
      cubeVertices: cubeVertices,
    );
  }

  static CubeGeometryResult fromDetections(
    List<DetectionResult> detections, {
    Size? imageSize,
    int gridSize = 3,
  }) {
    final points = <Offset>[];
    final usePixelSpace = imageSize != null;
    final scaleX = imageSize?.width ?? 1.0;
    final scaleY = imageSize?.height ?? 1.0;

    for (final detection in detections) {
      if (detection.bbox.length < 4) {
        continue;
      }

      final isNormalized =
          detection.bbox[0] <= 1.0 &&
          detection.bbox[1] <= 1.0 &&
          detection.bbox[2] <= 1.0 &&
          detection.bbox[3] <= 1.0;

      final left = usePixelSpace && isNormalized
          ? detection.bbox[0] * scaleX
          : detection.bbox[0];
      final top = usePixelSpace && isNormalized
          ? detection.bbox[1] * scaleY
          : detection.bbox[1];
      final width = usePixelSpace && isNormalized
          ? detection.bbox[2] * scaleX
          : detection.bbox[2];
      final height = usePixelSpace && isNormalized
          ? detection.bbox[3] * scaleY
          : detection.bbox[3];
      final right = left + width;
      final bottom = top + height;

      points.addAll([
        Offset(left, top),
        Offset(right, top),
        Offset(right, bottom),
        Offset(left, bottom),
      ]);
    }

    if (points.isEmpty) {
      return const CubeGeometryResult(
        outline: [],
        samplePoints: [],
        bounds: null,
      );
    }

    final hull = _convexHull(points);
    final outline = hull.length >= 4 ? hull : _axisAlignedRectangle(points);
    final orderedOutline = _orderClockwise(outline);
    final quad = orderedOutline.length >= 4
        ? orderedOutline.take(4).toList()
        : orderedOutline;
    final samplePoints = quad.length == 4
        ? _buildGridPoints(quad, gridSize)
        : const <Offset>[];
    final bounds = _boundsFromPoints(points);

    return CubeGeometryResult(
      outline: orderedOutline,
      samplePoints: samplePoints,
      bounds: bounds,
    );
  }

  static Rect? _boundsFromPoints(List<Offset> points) {
    if (points.isEmpty) return null;
    final xs = points.map((p) => p.dx).toList(growable: false);
    final ys = points.map((p) => p.dy).toList(growable: false);
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static List<Offset> _axisAlignedRectangle(List<Offset> points) {
    final bounds = _boundsFromPoints(points);
    if (bounds == null) return const [];
    return [
      Offset(bounds.left, bounds.top),
      Offset(bounds.right, bounds.top),
      Offset(bounds.right, bounds.bottom),
      Offset(bounds.left, bounds.bottom),
    ];
  }

  static List<Offset> _rectToOutline(Rect rect) {
    return [
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
    ];
  }

  static double _polygonAreaAbs(List<Offset> poly) {
    if (poly.length < 3) return 0.0;
    var sum = 0.0;
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      sum += (a.dx * b.dy) - (b.dx * a.dy);
    }
    return sum.abs() * 0.5;
  }

  static List<Offset> _buildGridPoints(List<Offset> quad, int gridSize) {
    if (quad.length < 4 || gridSize <= 0) return const [];

    final points = <Offset>[];
    for (var row = 0; row < gridSize; row++) {
      final v = (row + 0.5) / gridSize;
      for (var col = 0; col < gridSize; col++) {
        final u = (col + 0.5) / gridSize;
        points.add(_lerpQuad(quad, u, v));
      }
    }
    return points;
  }

  /// Bilinear-interpolates a point within [quad] (topLeft, topRight,
  /// bottomRight, bottomLeft), at fractional position (u, v) in [0,1]x[0,1].
  static Offset _lerpQuad(List<Offset> quad, double u, double v) {
    final leftEdge = _lerp(quad[0], quad[3], v);
    final rightEdge = _lerp(quad[1], quad[2], v);
    return _lerp(leftEdge, rightEdge, u);
  }

  /// Several sample points spread across a single grid cell of [quad]
  /// (bilinear interpolation, same convention as [_buildGridPoints]/
  /// [samplePoints]: row 0/col 0 is the top-left cell), for averaging a
  /// sticker's color across multiple spots instead of trusting one point -
  /// robust to localized glare, shadow, or dirt. Point 0 is always the cell
  /// center (matches the corresponding entry in [samplePoints] exactly);
  /// the rest are small offsets around it, kept well inside the cell
  /// (governed by [spread], a fraction of one cell's width/height) so they
  /// don't bleed into neighboring stickers. Also used by [CubeGeometryPainter]
  /// to draw dots at the exact points a color extraction would sample, so the
  /// visualization never drifts out of sync with the real algorithm.
  static List<Offset> cellSubSamplePoints(
    List<Offset> quad,
    int row,
    int col, {
    int gridSize = 3,
    int pointsPerCell = 5,
    double spread = 0.22,
  }) {
    if (quad.length < 4 || pointsPerCell <= 0) return const [];

    final cu = (col + 0.5) / gridSize;
    final cv = (row + 0.5) / gridSize;
    final du = spread / gridSize;
    final dv = spread / gridSize;

    const candidateOffsets = [
      Offset(0, 0),
      Offset(-1, 0),
      Offset(1, 0),
      Offset(0, -1),
      Offset(0, 1),
      Offset(-0.7, -0.7),
      Offset(0.7, -0.7),
      Offset(-0.7, 0.7),
      Offset(0.7, 0.7),
    ];

    return candidateOffsets
        .take(pointsPerCell)
        .map(
          (o) => _lerpQuad(
            quad,
            (cu + o.dx * du).clamp(0.0, 1.0),
            (cv + o.dy * dv).clamp(0.0, 1.0),
          ),
        )
        .toList(growable: false);
  }

  static List<Offset> _convexHull(List<Offset> points) {
    if (points.length <= 3) {
      return _orderClockwise(points);
    }

    final sorted = [...points]
      ..sort((a, b) {
        final cmpX = a.dx.compareTo(b.dx);
        if (cmpX != 0) return cmpX;
        return a.dy.compareTo(b.dy);
      });

    bool cross(Offset o, Offset a, Offset b) {
      return (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx) <= 0;
    }

    final lower = <Offset>[];
    for (final p in sorted) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, p)) {
        lower.removeLast();
      }
      lower.add(p);
    }

    final upper = <Offset>[];
    for (final p in sorted.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, p)) {
        upper.removeLast();
      }
      upper.add(p);
    }

    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  static List<Offset> _orderClockwise(List<Offset> points) {
    if (points.length <= 1) return points;

    final center = Offset(
      points.map((p) => p.dx).reduce((a, b) => a + b) / points.length,
      points.map((p) => p.dy).reduce((a, b) => a + b) / points.length,
    );

    final ordered = [...points]
      ..sort((a, b) {
        final angleA = math.atan2(a.dy - center.dy, a.dx - center.dx);
        final angleB = math.atan2(b.dy - center.dy, b.dx - center.dx);
        return angleA.compareTo(angleB);
      });

    var topLeftIndex = 0;
    var bestScore = double.infinity;
    for (var i = 0; i < ordered.length; i++) {
      final score = ordered[i].dy * 100000 + ordered[i].dx;
      if (score < bestScore) {
        bestScore = score;
        topLeftIndex = i;
      }
    }

    return [
      ...ordered.sublist(topLeftIndex),
      ...ordered.sublist(0, topLeftIndex),
    ];
  }

  static Offset _lerp(Offset a, Offset b, double t) {
    return Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
  }
}

class CubeGeometryPainter extends CustomPainter {
  final CubeGeometryResult geometry;
  final Size sourceSize;
  final int rotationQuarterTurns;
  final List<DetectionResult> detections;

  /// Wireframe/dot colors, sourced from the active theme's ColorScheme
  /// (light vs dark) rather than hardcoded - front-face elements use
  /// [primaryColor], back-face/connector/grid elements use [secondaryColor].
  /// CustomPainter has no BuildContext, so the caller reads these from
  /// `Theme.of(context).colorScheme` and passes them in.
  final Color primaryColor;
  final Color secondaryColor;

  CubeGeometryPainter({
    required this.geometry,
    required this.sourceSize,
    required this.primaryColor,
    required this.secondaryColor,
    this.rotationQuarterTurns = 0,
    this.detections = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!geometry.hasOutline ||
        sourceSize.width <= 0 ||
        sourceSize.height <= 0) {
      return;
    }

    final scale = math.max(
      size.width / sourceSize.width,
      size.height / sourceSize.height,
    );
    final displayWidth = sourceSize.width * scale;
    final displayHeight = sourceSize.height * scale;
    final offsetX = (size.width - displayWidth) / 2.0;
    final offsetY = (size.height - displayHeight) / 2.0;

    Offset rotatePoint(Offset point) {
      switch (rotationQuarterTurns % 4) {
        case 1:
          return Offset(point.dy, sourceSize.width - point.dx);
        case 2:
          return Offset(
            sourceSize.width - point.dx,
            sourceSize.height - point.dy,
          );
        case 3:
          return Offset(sourceSize.height - point.dy, point.dx);
        default:
          return point;
      }
    }

    Offset mapPoint(Offset point) {
      final rotated = rotatePoint(point);
      final adjustedWidth = rotationQuarterTurns.isOdd
          ? sourceSize.height
          : sourceSize.width;
      final adjustedHeight = rotationQuarterTurns.isOdd
          ? sourceSize.width
          : sourceSize.height;
      final adjustedScale = math.max(
        size.width / adjustedWidth,
        size.height / adjustedHeight,
      );
      final displayedWidth = adjustedWidth * adjustedScale;
      final displayedHeight = adjustedHeight * adjustedScale;
      final adjustedOffsetX = (size.width - displayedWidth) / 2.0;
      final adjustedOffsetY = (size.height - displayedHeight) / 2.0;

      return Offset(
        rotated.dx * adjustedScale + adjustedOffsetX,
        rotated.dy * adjustedScale + adjustedOffsetY,
      );
    }

    // Kept very transparent (roughly 90%) so the overlay stays out of the
    // way of the actual camera view it's annotating.
    final fill = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    final outline = geometry.outline;
    path.moveTo(mapPoint(outline.first).dx, mapPoint(outline.first).dy);
    for (var i = 1; i < outline.length; i++) {
      final mapped = mapPoint(outline[i]);
      path.lineTo(mapped.dx, mapped.dy);
    }
    path.close();

    canvas.drawPath(path, fill);

    _paintCubeWireframe(canvas, mapPoint);

    if (outline.length >= 4) {
      final rowPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      for (var row = 0; row < 3; row++) {
        final start = CubeGeometry._lerpQuad(outline, 0, (row + 0.5) / 3);
        final end = CubeGeometry._lerpQuad(outline, 1, (row + 0.5) / 3);
        canvas.drawLine(mapPoint(start), mapPoint(end), rowPaint);
      }
      for (var col = 0; col < 3; col++) {
        final start = CubeGeometry._lerpQuad(outline, (col + 0.5) / 3, 0);
        final end = CubeGeometry._lerpQuad(outline, (col + 0.5) / 3, 1);
        canvas.drawLine(mapPoint(start), mapPoint(end), rowPaint);
      }

      // Small dots at the actual points a color capture would sample from
      // each sticker cell - visual feedback for "this is what's being read",
      // using the same points FaceColorExtractor averages over.
      final samplePaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 3; col++) {
          final points = CubeGeometry.cellSubSamplePoints(outline, row, col);
          for (final point in points) {
            canvas.drawCircle(mapPoint(point), 2.5, samplePaint);
          }
        }
      }
    }
  }

  /// Draws all 8 detected corners and the 12 edges between them, like a
  /// wireframe cube sketched on paper: solid bright edges for the front
  /// face, dashed cool-toned edges for the back face and the corners
  /// connecting front to back. Only draws an edge when both its corners are
  /// visible, and only draws a corner dot when that corner itself is
  /// visible - a partially-occluded cube still draws whatever is known.
  void _paintCubeWireframe(Canvas canvas, Offset Function(Offset) mapPoint) {
    final vertices = geometry.cubeVertices;
    if (vertices.length < 8) {
      return;
    }

    // Front face uses primaryColor, back face/connectors use secondaryColor -
    // just the two theme colors, kept very transparent (roughly 90%) so the
    // overlay stays out of the way of the camera feed underneath it.
    final frontColor = primaryColor;
    final backColor = secondaryColor;
    final connectorColor = secondaryColor;

    final frontEdgePaint = Paint()
      ..color = frontColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final backEdgePaint = Paint()
      ..color = backColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final connectorEdgePaint = Paint()
      ..color = connectorColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final edge in CubeGeometryResult.wireframeEdges) {
      final a = vertices[edge[0]];
      final b = vertices[edge[1]];
      if (!a.visible || !b.visible) {
        continue;
      }

      final isFrontEdge = edge[0] < 4 && edge[1] < 4;
      final isBackEdge = edge[0] >= 4 && edge[1] >= 4;
      final paint = isFrontEdge
          ? frontEdgePaint
          : (isBackEdge ? backEdgePaint : connectorEdgePaint);
      final from = mapPoint(a.position);
      final to = mapPoint(b.position);

      if (isFrontEdge) {
        canvas.drawLine(from, to, paint);
      } else {
        _drawDashedLine(canvas, from, to, paint);
      }
    }

    for (final vertex in vertices) {
      if (!vertex.visible) {
        continue;
      }
      final isFront = vertex.index < 4;
      final center = mapPoint(vertex.position);
      final dotColor = isFront ? frontColor : backColor;

      canvas.drawCircle(
        center,
        6,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        4,
        Paint()
          ..color = dotColor.withValues(alpha: 0.15 + 0.35 * vertex.score.clamp(0.0, 1.0))
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    double dashLength = 8,
    double gapLength = 6,
  }) {
    final total = (to - from).distance;
    if (total <= 0) {
      return;
    }
    final direction = (to - from) / total;
    var covered = 0.0;
    while (covered < total) {
      final segmentEnd = math.min(covered + dashLength, total);
      canvas.drawLine(
        from + direction * covered,
        from + direction * segmentEnd,
        paint,
      );
      covered += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CubeGeometryPainter oldDelegate) {
    return oldDelegate.geometry.outline != geometry.outline ||
        oldDelegate.geometry.samplePoints != geometry.samplePoints ||
        oldDelegate.geometry.cubeVertices != geometry.cubeVertices ||
        oldDelegate.sourceSize != sourceSize ||
        oldDelegate.rotationQuarterTurns != rotationQuarterTurns ||
        oldDelegate.detections != detections ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
