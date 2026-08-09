import 'dart:io';
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_pytorch/flutter_pytorch.dart';

class DetectionResult {
  final String color;
  final double confidence;
  final List<double> bbox; // [x, y, width, height]

  DetectionResult({
    required this.color,
    required this.confidence,
    required this.bbox,
  });
}

class DetectorDebugFrame {
  final int modelDetections;
  final int rawCandidates;
  final int strictCandidates;
  final int fallbackCandidates;
  final double bestModelScore;
  final double bestKeptScore;
  final bool wasSlow;
  final int inferenceMs;
  final String activeModel;
  final String? lastError;

  const DetectorDebugFrame({
    this.modelDetections = 0,
    this.rawCandidates = 0,
    this.strictCandidates = 0,
    this.fallbackCandidates = 0,
    this.bestModelScore = 0.0,
    this.bestKeptScore = 0.0,
    this.wasSlow = false,
    this.inferenceMs = 0,
    this.activeModel = '',
    this.lastError,
  });
}

class _ParsedDetections {
  final List<DetectionResult> results;
  final int rawCandidates;
  final int strictCandidates;
  final int fallbackCandidates;

  const _ParsedDetections({
    required this.results,
    required this.rawCandidates,
    required this.strictCandidates,
    required this.fallbackCandidates,
  });
}

class RubikDetector {
  static const String preferredModelPath = 'assets/models/best_tensor.ptl';
  static const String fallbackModelPath = 'assets/models/best_tensor.torchscript';
  static const String labelsPath = 'assets/models/cube_labels.txt';
  static const int inputSize = 640;
  static const int inferenceTimeoutMs = 1500;
  static const int slowInferenceMs = 2500;
  static const int maxConsecutiveSlowFramesBeforeModelSwap = 3;
  static const double scoreThreshold = 0.08;
  static const double minAreaRatio = 0.0015;
  static const double maxAreaRatio = 0.97;
  static const double minAspectRatio = 0.16;
  static const double maxAspectRatio = 6.00;
  static const double maxCenterDistance = 1.35;
  static const double maxSpanRatio = 0.98;

  // Fallback gates are intentionally relaxed to avoid dropping valid cubes.
  static const double fallbackScoreThreshold = 0.04;
  static const double fallbackMinAreaRatio = 0.001;
  static const double fallbackMaxAreaRatio = 0.99;
  static const double fallbackMinAspectRatio = 0.12;
  static const double fallbackMaxAspectRatio = 7.00;
  static const double fallbackMaxCenterDistance = 1.45;
  static const double fallbackMaxSpanRatio = 0.99;
  static const int boxesLimit = 6;
  static const bool pluginRotatesInputClockwise90 = true;

  ClassificationModel? _model;
  List<String> _labels = const [];
  bool _modelLoaded = false;
  Future<void>? _loadFuture;
  DetectorDebugFrame _lastDebugFrame = const DetectorDebugFrame(
    activeModel: preferredModelPath,
  );
  int _modelCandidateIndex = 0;
  int _consecutiveSlowFrames = 0;

  DetectorDebugFrame get lastDebugFrame => _lastDebugFrame;

  String get currentModelAsset =>
      _modelCandidateIndex == 0 ? preferredModelPath : fallbackModelPath;

  Future<void> preloadModel() async {
    if (_loadFuture != null) {
      await _loadFuture;
      return;
    }

    _loadFuture = _ensureModelLoaded();
    await _loadFuture;
  }

  Future<List<DetectionResult>> detect(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found: $imagePath');
    }

    return detectFromBytes(await file.readAsBytes());
  }

  Future<List<DetectionResult>> detectFromBytes(Uint8List imageBytes) async {
    await preloadModel();

    final inferenceStopwatch = Stopwatch()..start();
    try {
      final prediction = await _model!
          .getImagePredictionList(
            imageBytes,
            mean: const [0.0, 0.0, 0.0],
            std: const [1.0, 1.0, 1.0],
          )
          .timeout(const Duration(milliseconds: inferenceTimeoutMs));
      inferenceStopwatch.stop();

      final inferenceMs = inferenceStopwatch.elapsedMilliseconds;
      final wasSlow = inferenceMs >= slowInferenceMs;
      if (wasSlow) {
        _consecutiveSlowFrames += 1;
        if (_consecutiveSlowFrames >= maxConsecutiveSlowFramesBeforeModelSwap) {
          _consecutiveSlowFrames = 0;
          await _switchModelCandidate();
        }
      } else {
        _consecutiveSlowFrames = 0;
      }

      final parsed = _parseRawDetections(prediction);
      var bestModelScore = 0.0;
      for (final item in parsed.results) {
        if (item.confidence > bestModelScore) {
          bestModelScore = item.confidence;
        }
      }

      var bestKeptScore = 0.0;
      for (final item in parsed.results) {
        if (item.confidence > bestKeptScore) {
          bestKeptScore = item.confidence;
        }
      }

      _lastDebugFrame = DetectorDebugFrame(
        modelDetections: parsed.rawCandidates,
        rawCandidates: parsed.rawCandidates,
        strictCandidates: parsed.strictCandidates,
        fallbackCandidates: parsed.fallbackCandidates,
        bestModelScore: bestModelScore,
        bestKeptScore: bestKeptScore,
        wasSlow: wasSlow,
        inferenceMs: inferenceMs,
        activeModel: currentModelAsset,
      );

      return parsed.results;
    } on TimeoutException {
      inferenceStopwatch.stop();
      _lastDebugFrame = DetectorDebugFrame(
        activeModel: currentModelAsset,
        inferenceMs: inferenceStopwatch.elapsedMilliseconds,
        lastError:
            'inference timeout ${inferenceStopwatch.elapsedMilliseconds}ms; plugin likely waiting due model output mismatch (expected Tuple)',
      );
      return const <DetectionResult>[];
    } catch (error) {
      inferenceStopwatch.stop();
      _lastDebugFrame = DetectorDebugFrame(
        activeModel: currentModelAsset,
        inferenceMs: inferenceStopwatch.elapsedMilliseconds,
        lastError: error.toString(),
      );
      rethrow;
    }
  }

  _ParsedDetections _parseRawDetections(List<double?>? prediction) {
    final strictResults = <DetectionResult>[];
    final fallbackResults = <DetectionResult>[];
    final rawCandidates = prediction == null
        ? <DetectionResult>[]
        : _decodeRawCandidates(prediction);
    if (prediction == null) {
      return const _ParsedDetections(
        results: <DetectionResult>[],
        rawCandidates: 0,
        strictCandidates: 0,
        fallbackCandidates: 0,
      );
    }

    for (final detection in rawCandidates) {
      final score = detection.confidence.clamp(0.0, 1.0);
      final label = detection.color;

      var left = detection.bbox[0].clamp(0.0, 1.0);
      var top = detection.bbox[1].clamp(0.0, 1.0);
      var width = detection.bbox[2].clamp(0.0, 1.0);
      var height = detection.bbox[3].clamp(0.0, 1.0);

      if (pluginRotatesInputClockwise90) {
        final corrected = _undoClockwise90Rotation(
          left.toDouble(),
          top.toDouble(),
          width.toDouble(),
          height.toDouble(),
        );
        left = corrected[0];
        top = corrected[1];
        width = corrected[2];
        height = corrected[3];
      }

      final right = (left + width).clamp(0.0, 1.0);
      final bottom = (top + height).clamp(0.0, 1.0);

      if (width <= 0.0 || height <= 0.0) {
        continue;
      }

      final area = width * height;
      final aspect = width / math.max(height, 1e-6);
      final cx = left + width / 2.0;
      final cy = top + height / 2.0;
      final centerDistance = math.sqrt(
        math.pow(cx - 0.5, 2) + math.pow(cy - 0.5, 2),
      );
      final touchesHorizontalEdges = left <= 0.01 && right >= 0.99;
      final touchesVerticalEdges = top <= 0.01 && bottom >= 0.99;

      if (touchesHorizontalEdges || touchesVerticalEdges) {
        continue;
      }
      final spansTooWide = width >= maxSpanRatio;
      final spansTooTall = height >= maxSpanRatio;
      final isClearlyFullscreenFalsePositive =
          spansTooWide ||
          spansTooTall ||
          touchesHorizontalEdges ||
          touchesVerticalEdges;

      if (isClearlyFullscreenFalsePositive) {
        continue;
      }

      final candidate = DetectionResult(
        color: label,
        confidence: score.toDouble(),
        bbox: [
          left.toDouble(),
          top.toDouble(),
          width.toDouble(),
          height.toDouble(),
        ],
      );

      final passesStrict =
          score >= scoreThreshold &&
          area >= minAreaRatio &&
          area <= maxAreaRatio &&
          aspect >= minAspectRatio &&
          aspect <= maxAspectRatio &&
          centerDistance <= maxCenterDistance;

      if (passesStrict) {
        strictResults.add(candidate);
        continue;
      }

      final passesFallback =
          score >= fallbackScoreThreshold &&
          area >= fallbackMinAreaRatio &&
          area <= fallbackMaxAreaRatio &&
          aspect >= fallbackMinAspectRatio &&
          aspect <= fallbackMaxAspectRatio &&
          centerDistance <= fallbackMaxCenterDistance &&
          width <= fallbackMaxSpanRatio &&
          height <= fallbackMaxSpanRatio;

      if (passesFallback) {
        fallbackResults.add(candidate);
      }
    }

    strictResults.sort(
      (a, b) => _candidateRank(b).compareTo(_candidateRank(a)),
    );
    if (strictResults.isNotEmpty) {
      return _ParsedDetections(
        results: [strictResults.first],
        rawCandidates: rawCandidates.length,
        strictCandidates: strictResults.length,
        fallbackCandidates: fallbackResults.length,
      );
    }

    fallbackResults.sort(
      (a, b) => _candidateRank(b).compareTo(_candidateRank(a)),
    );
    if (fallbackResults.isNotEmpty) {
      return _ParsedDetections(
        results: [fallbackResults.first],
        rawCandidates: rawCandidates.length,
        strictCandidates: strictResults.length,
        fallbackCandidates: fallbackResults.length,
      );
    }

    if (rawCandidates.isNotEmpty) {
      rawCandidates.sort(
        (a, b) => _candidateRank(b).compareTo(_candidateRank(a)),
      );
      return _ParsedDetections(
        results: [rawCandidates.first],
        rawCandidates: rawCandidates.length,
        strictCandidates: strictResults.length,
        fallbackCandidates: fallbackResults.length,
      );
    }

    return _ParsedDetections(
      results: const <DetectionResult>[],
      rawCandidates: rawCandidates.length,
      strictCandidates: strictResults.length,
      fallbackCandidates: fallbackResults.length,
    );
  }

  double _candidateRank(DetectionResult d) {
    final width = d.bbox[2];
    final height = d.bbox[3];
    final area = width * height;
    final aspect = width / math.max(height, 1e-6);
    final cx = d.bbox[0] + width / 2.0;
    final cy = d.bbox[1] + height / 2.0;
    final centerDistance = math.sqrt(
      math.pow(cx - 0.5, 2) + math.pow(cy - 0.5, 2),
    );

    // Prefer confident, square-ish, mid-sized, center-near candidates.
    final areaPenalty = (area - 0.18).abs();
    final aspectPenalty = (aspect - 1.0).abs();
    return d.confidence -
        (0.55 * areaPenalty) -
        (0.25 * aspectPenalty) -
        (0.20 * centerDistance);
  }

  Future<void> _ensureModelLoaded() async {
    if (_modelLoaded) {
      return;
    }

    final model = await _loadModel();
    final labels = await _loadLabels();

    _model = model;
    _labels = labels;
    _modelLoaded = true;
  }

  Future<ClassificationModel> _loadModel() async {
    final candidates = <String>[preferredModelPath, fallbackModelPath];
    Object? lastError;

    for (var attempt = 0; attempt < candidates.length; attempt++) {
      final candidate =
          candidates[(_modelCandidateIndex + attempt) % candidates.length];
      try {
        return await FlutterPytorch.loadClassificationModel(
          candidate,
          inputSize,
          inputSize,
          labelPath: labelsPath,
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Failed to load Rubik detector model: $lastError');
  }

  Future<void> _switchModelCandidate() async {
    _modelCandidateIndex = (_modelCandidateIndex + 1) % 2;
    _model = null;
    _modelLoaded = false;
    _loadFuture = null;
    try {
      await preloadModel();
    } catch (_) {
      // Keep current behavior; next frame will retry.
    }
  }

  List<DetectionResult> _decodeRawCandidates(List<double?> raw) {
    final values = raw.map((v) => v ?? 0.0).toList(growable: false);
    final decodedVariants = <List<DetectionResult>>[
      _decodeInterleavedXyxyCls(values),
      _decodeInterleavedXywh(values),
      _decodeChannelMajorXywh(values),
    ];

    decodedVariants.sort((a, b) => _decodeQuality(b).compareTo(_decodeQuality(a)));
    final best = decodedVariants.isNotEmpty ? decodedVariants.first : const <DetectionResult>[];

    best.sort((a, b) => _candidateRank(b).compareTo(_candidateRank(a)));
    return best.take(200).toList(growable: false);
  }

  double _decodeQuality(List<DetectionResult> detections) {
    if (detections.isEmpty) return 0.0;
    final plausible = detections
        .where((d) => d.confidence >= 0.01 && d.confidence <= 1.2)
        .length;
    var best = 0.0;
    for (final d in detections) {
      if (d.confidence > best) best = d.confidence;
    }
    return plausible * 10 + best;
  }

  List<DetectionResult> _decodeInterleavedXyxyCls(List<double> v) {
    if (v.length % 6 != 0) return const <DetectionResult>[];
    final out = <DetectionResult>[];
    for (var i = 0; i + 5 < v.length; i += 6) {
      final x1 = _norm(v[i]);
      final y1 = _norm(v[i + 1]);
      final x2 = _norm(v[i + 2]);
      final y2 = _norm(v[i + 3]);
      final score = v[i + 4];
      final left = math.min(x1, x2);
      final top = math.min(y1, y2);
      final width = (x1 - x2).abs();
      final height = (y1 - y2).abs();
      if (width <= 0 || height <= 0) continue;
      out.add(
        DetectionResult(
          color: _labels.isNotEmpty ? _labels.first : 'cube',
          confidence: score,
          bbox: [left, top, width, height],
        ),
      );
    }
    return out;
  }

  List<DetectionResult> _decodeInterleavedXywh(List<double> v) {
    if (v.length % 5 != 0) return const <DetectionResult>[];
    final out = <DetectionResult>[];
    for (var i = 0; i + 4 < v.length; i += 5) {
      final cx = _norm(v[i]);
      final cy = _norm(v[i + 1]);
      final w = _norm(v[i + 2]).abs();
      final h = _norm(v[i + 3]).abs();
      final score = v[i + 4];
      final left = (cx - w / 2.0).clamp(0.0, 1.0);
      final top = (cy - h / 2.0).clamp(0.0, 1.0);
      if (w <= 0 || h <= 0) continue;
      out.add(
        DetectionResult(
          color: _labels.isNotEmpty ? _labels.first : 'cube',
          confidence: score,
          bbox: [left, top, w.clamp(0.0, 1.0), h.clamp(0.0, 1.0)],
        ),
      );
    }
    return out;
  }

  List<DetectionResult> _decodeChannelMajorXywh(List<double> v) {
    if (v.length % 5 != 0) return const <DetectionResult>[];
    final n = v.length ~/ 5;
    final out = <DetectionResult>[];
    for (var i = 0; i < n; i++) {
      final cx = _norm(v[i]);
      final cy = _norm(v[n + i]);
      final w = _norm(v[(2 * n) + i]).abs();
      final h = _norm(v[(3 * n) + i]).abs();
      final score = v[(4 * n) + i];
      final left = (cx - w / 2.0).clamp(0.0, 1.0);
      final top = (cy - h / 2.0).clamp(0.0, 1.0);
      if (w <= 0 || h <= 0) continue;
      out.add(
        DetectionResult(
          color: _labels.isNotEmpty ? _labels.first : 'cube',
          confidence: score,
          bbox: [left, top, w.clamp(0.0, 1.0), h.clamp(0.0, 1.0)],
        ),
      );
    }
    return out;
  }

  double _norm(double value) {
    if (!value.isFinite) return 0.0;
    if (value > 1.5 || value < -0.5) {
      return (value / inputSize).clamp(0.0, 1.0);
    }
    return value.clamp(0.0, 1.0);
  }

  List<double> _undoClockwise90Rotation(
    double left,
    double top,
    double width,
    double height,
  ) {
    final x1 = left;
    final y1 = top;
    final x2 = (left + width).clamp(0.0, 1.0);
    final y2 = (top + height).clamp(0.0, 1.0);

    Offset inv(double x, double y) {
      // Inverse of plugin's CW90 rotation: rot(x,y) -> orig(y, 1 - x)
      return Offset(y.clamp(0.0, 1.0), (1.0 - x).clamp(0.0, 1.0));
    }

    final p1 = inv(x1, y1);
    final p2 = inv(x2, y1);
    final p3 = inv(x2, y2);
    final p4 = inv(x1, y2);

    final minX = math.min(math.min(p1.dx, p2.dx), math.min(p3.dx, p4.dx));
    final maxX = math.max(math.max(p1.dx, p2.dx), math.max(p3.dx, p4.dx));
    final minY = math.min(math.min(p1.dy, p2.dy), math.min(p3.dy, p4.dy));
    final maxY = math.max(math.max(p1.dy, p2.dy), math.max(p3.dy, p4.dy));

    return [
      minX.clamp(0.0, 1.0),
      minY.clamp(0.0, 1.0),
      (maxX - minX).clamp(0.0, 1.0),
      (maxY - minY).clamp(0.0, 1.0),
    ];
  }

  Future<List<String>> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString(labelsPath);
      return raw
          .split(RegExp(r'[\r\n]+'))
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim())
          .toList();
    } catch (_) {
      return const ['cube'];
    }
  }
}
