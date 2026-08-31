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
  /// together, and classifies the result against [referenceColors] (defaults
  /// to [kMeasuredReferenceColors] - real photographed sticker colors, not
  /// [kFaceColors]'s idealized Material swatches, since classifying camera
  /// pixels against the latter confuses real orange stickers for red).
  static List<List<SampledSticker>> extract(
    img.Image image,
    List<Offset> quad, {
    int pointsPerCell = defaultPointsPerCell,
    int patchRadius = 4,
    Map<Face, Color> referenceColors = kMeasuredReferenceColors,
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
        final match = _classify(avg, referenceColors);
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
  /// classified colors above [minConfidence], null otherwise. Always stores
  /// the canonical [kFaceColors] value for the matched identity, even when
  /// classification was judged against a calibrated [referenceColors].
  static List<List<Color?>> extractClassified(
    img.Image image,
    List<Offset> quad, {
    int pointsPerCell = defaultPointsPerCell,
    int patchRadius = 4,
    double minConfidence = defaultMinConfidence,
    Map<Face, Color> referenceColors = kMeasuredReferenceColors,
  }) {
    final sampled = extract(
      image,
      quad,
      pointsPerCell: pointsPerCell,
      patchRadius: patchRadius,
      referenceColors: referenceColors,
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

  static ({Face? face, double confidence}) _classify(
    Color sampled,
    Map<Face, Color> referenceColors,
  ) {
    final lab = _rgbToLab(sampled);

    Face? bestFace;
    var bestDistance = double.infinity;
    for (final face in Face.values) {
      final refLab = _rgbToLab(referenceColors[face] ?? kMeasuredReferenceColors[face]!);
      final distance = _labDistance(lab, refLab);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestFace = face;
      }
    }

    // Empirically calibrated: against a 90-cell hand-verified test set
    // spanning bright/dim/outdoor lighting, this threshold gives ~80%
    // precision at 0.5 confidence and ~94% at 0.75. LAB scored 79%
    // exact-match accuracy on that set vs. 69% for a hue/saturation-weighted
    // HSV distance also tried here, mainly by fixing warm-lit white/cream
    // stickers that HSV read as orange or yellow.
    //
    // Per-session color *calibration* (adapting these references to a scan's
    // specific lighting) was tried on top of this twice, with both HSV and
    // Lab as the base metric, and dropped both times: any drift in one
    // identity's reference - even from a completely legitimate read - risks
    // encroaching on whichever other identity sits closest to it (white,
    // being closest to neutral of all 6; orange/red, being the closest pair
    // to each other). A single clean read started stealing a different
    // color's later reads, with *rising* confidence, not falling - no floor
    // on the read itself can catch that, since the read genuinely is a good
    // instance of its own color. Classification here always uses the fixed
    // [kMeasuredReferenceColors] (via [referenceColors]'s default) instead.
    const maxPlausibleDistance = 1.2;
    final confidence = (1.0 - (bestDistance / maxPlausibleDistance)).clamp(0.0, 1.0);
    return (face: bestFace, confidence: confidence);
  }

  /// Converts sRGB (as Flutter hands it back: [Color.r]/[Color.g]/[Color.b]
  /// already normalized to 0..1) to CIE L*a*b*, D65 illuminant - perceptually
  /// closer to how the eye separates colors than HSV (see [_classify]'s doc
  /// comment for the measured accuracy difference).
  static ({double l, double a, double b}) _rgbToLab(Color color) {
    double toLinear(double c) =>
        c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

    final r = toLinear(color.r);
    final g = toLinear(color.g);
    final b = toLinear(color.b);

    final x = r * 0.4124 + g * 0.3576 + b * 0.1805;
    final y = r * 0.2126 + g * 0.7152 + b * 0.0722;
    final z = r * 0.0193 + g * 0.1192 + b * 0.9505;

    const xn = 0.95047;
    const yn = 1.0;
    const zn = 1.08883;
    double f(double t) =>
        t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : (7.787 * t + 16 / 116);

    final fx = f(x / xn);
    final fy = f(y / yn);
    final fz = f(z / zn);

    return (l: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz));
  }

  /// Plain Euclidean distance in L*a*b* space (CIE76) - scaled down by 100
  /// purely so [_classify]'s `maxPlausibleDistance` constant didn't need
  /// retuning when this replaced the old HSV-based distance.
  static double _labDistance(
    ({double l, double a, double b}) a,
    ({double l, double a, double b}) b,
  ) {
    final dl = a.l - b.l;
    final da = a.a - b.a;
    final db = a.b - b.b;
    return math.sqrt(dl * dl + da * da + db * db) / 100.0;
  }
}
