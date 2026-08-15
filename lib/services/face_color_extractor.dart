import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../cube_face.dart';
import 'cube_geometry.dart';

/// A single grid cell's sampled/classified color, kept together so a caller
/// can decide what to do with low-confidence reads (leave blank for manual
/// fill, feed into a future constraint-solving pass, etc.) instead of the
/// extractor silently guessing.
class SampledSticker {
  final Color sampledColor;
  final Face? classifiedFace;
  final double confidence; // 0..1, higher = more confident match

  const SampledSticker({
    required this.sampledColor,
    required this.classifiedFace,
    required this.confidence,
  });
}

class FaceColorExtractor {
  /// Below this confidence, [extractClassified] returns null for a cell
  /// rather than a guess - better to leave it for manual correction than to
  /// fill in something wrong with false confidence.
  static const double defaultMinConfidence = 0.5;

  /// Default number of points averaged per sticker cell. One point is fragile
  /// - a single spec of glare or shadow on that exact pixel skews the whole
  /// read - so this samples several spots spread across each sticker instead
  /// (see [CubeGeometry.cellSubSamplePoints]) and averages across all of them.
  static const int defaultPointsPerCell = 5;

  /// For each of the 3x3 grid cells of [quad] (front face corners: topLeft,
  /// topRight, bottomRight, bottomLeft, in [image]-pixel coordinates),
  /// samples [pointsPerCell] points spread across that sticker (small patch
  /// average at each, to also smooth out sensor noise), averages them
  /// together, and classifies the result against the 6 canonical cube
  /// sticker colors.
  static List<List<SampledSticker>> extract(
    img.Image image,
    List<Offset> quad, {
    int pointsPerCell = defaultPointsPerCell,
    int patchRadius = 4,
  }) {
    if (quad.length < 4) {
      throw ArgumentError(
        'Expected a 4-point quad (front face corners), got ${quad.length}',
      );
    }

    return List.generate(3, (row) {
      return List.generate(3, (col) {
        final points = CubeGeometry.cellSubSamplePoints(
          quad,
          row,
          col,
          pointsPerCell: pointsPerCell,
        );
        final avg = _averageMultiPoint(image, points, patchRadius);
        final match = _classify(avg);
        return SampledSticker(
          sampledColor: avg,
          classifiedFace: match.face,
          confidence: match.confidence,
        );
      });
    });
  }

  /// Convenience wrapper over [extract] for callers that just want a
  /// grid of colors to store (e.g. into a `List<List<Color?>>` face slot):
  /// classified colors above [minConfidence], null otherwise.
  static List<List<Color?>> extractClassified(
    img.Image image,
    List<Offset> quad, {
    int pointsPerCell = defaultPointsPerCell,
    int patchRadius = 4,
    double minConfidence = defaultMinConfidence,
  }) {
    final sampled = extract(
      image,
      quad,
      pointsPerCell: pointsPerCell,
      patchRadius: patchRadius,
    );
    return sampled
        .map(
          (row) => row
              .map(
                (cell) => cell.confidence >= minConfidence && cell.classifiedFace != null
                    ? kFaceColors[cell.classifiedFace!]
                    : null,
              )
              .toList(growable: false),
        )
        .toList(growable: false);
  }

  static Color _averageMultiPoint(
    img.Image image,
    List<Offset> points,
    int patchRadius,
  ) {
    var rSum = 0;
    var gSum = 0;
    var bSum = 0;
    var count = 0;

    for (final point in points) {
      final patch = _patchSum(image, point, patchRadius);
      if (patch == null) continue;
      rSum += patch.r;
      gSum += patch.g;
      bSum += patch.b;
      count++;
    }

    if (count == 0) {
      // Every sample point fell outside the image bounds.
      return const Color(0xFF000000);
    }
    return Color.fromARGB(255, rSum ~/ count, gSum ~/ count, bSum ~/ count);
  }

  static ({int r, int g, int b})? _patchSum(
    img.Image image,
    Offset center,
    int radius,
  ) {
    final cx = center.dx.round();
    final cy = center.dy.round();
    var rSum = 0;
    var gSum = 0;
    var bSum = 0;
    var count = 0;

    for (var dy = -radius; dy <= radius; dy++) {
      final y = cy + dy;
      if (y < 0 || y >= image.height) continue;
      for (var dx = -radius; dx <= radius; dx++) {
        final x = cx + dx;
        if (x < 0 || x >= image.width) continue;
        final pixel = image.getPixel(x, y);
        rSum += pixel.r.toInt();
        gSum += pixel.g.toInt();
        bSum += pixel.b.toInt();
        count++;
      }
    }

    if (count == 0) return null;
    return (r: rSum ~/ count, g: gSum ~/ count, b: bSum ~/ count);
  }

  static ({Face? face, double confidence}) _classify(Color sampled) {
    final hsv = HSVColor.fromColor(sampled);

    Face? bestFace;
    var bestDistance = double.infinity;
    for (final face in Face.values) {
      final refHsv = HSVColor.fromColor(kFaceColors[face]!);
      final distance = _hsvDistance(hsv, refHsv);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestFace = face;
      }
    }

    // Loose upper bound tuned for this 6-color palette, not a rigorous
    // scale - just enough to turn "distance to nearest color" into a
    // roughly-sane 0..1 confidence for gating auto-fill vs manual fallback.
    const maxPlausibleDistance = 1.2;
    final confidence = (1.0 - (bestDistance / maxPlausibleDistance)).clamp(0.0, 1.0);
    return (face: bestFace, confidence: confidence);
  }

  static double _hsvDistance(HSVColor a, HSVColor b) {
    // Hue is what actually separates the 5 chromatic cube colors, but it's
    // essentially noise for low-saturation (white/gray) samples - so scale
    // its weight by how saturated the *sampled* color is, letting
    // saturation/value distance dominate when hue can't be trusted.
    final hueDiff = (a.hue - b.hue).abs();
    final hueDist = math.min(hueDiff, 360 - hueDiff) / 180.0; // 0..1
    final satDist = (a.saturation - b.saturation).abs();
    final valDist = (a.value - b.value).abs();
    final hueWeight = a.saturation.clamp(0.0, 1.0);
    return hueDist * hueWeight * 1.2 + satDist * 0.6 + valDist * 0.3;
  }
}
