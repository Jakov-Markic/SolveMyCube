import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Describes how a frame was padded to a square before being handed to the
/// detector, so keypoints can be mapped back to the original (non-square)
/// camera frame. All fields are fractions of the square canvas side.
class LetterboxInfo {
  final double contentWidthFrac;
  final double contentHeightFrac;
  final double padXFrac;
  final double padYFrac;

  const LetterboxInfo({
    required this.contentWidthFrac,
    required this.contentHeightFrac,
    required this.padXFrac,
    required this.padYFrac,
  });

  static const LetterboxInfo identity = LetterboxInfo(
    contentWidthFrac: 1.0,
    contentHeightFrac: 1.0,
    padXFrac: 0.0,
    padYFrac: 0.0,
  );
}

/// A model-ready input tensor (NCHW, float32, 0..1) plus the padding
/// metadata needed to undo it once keypoints come back from the model, plus
/// the raw (unrotated, unpadded) RGB pixels the tensor was built from - kept
/// around so callers can sample actual sticker colors from the same frame a
/// detection came from, without re-decoding anything. Pass [contentWidth]/
/// [contentHeight] and [contentRgb] to `img.Image.fromBytes(...)` to get a
/// decodable image back; its pixel space matches [CubeGeometry.fromPoseResult]
/// when called with `imageSize: Size(contentWidth, contentHeight)`.
class ModelInputTensor {
  final Float32List tensor;
  final LetterboxInfo letterbox;
  final Uint8List contentRgb;
  final int contentWidth;
  final int contentHeight;

  const ModelInputTensor({
    required this.tensor,
    required this.letterbox,
    required this.contentRgb,
    required this.contentWidth,
    required this.contentHeight,
  });
}

/// Builds a model-ready input tensor from a decoded camera/image frame:
/// pads [source] to a square canvas (grey fill, matching the training-time
/// letterbox color), rotates it 90 degrees clockwise to match the upright
/// orientation the model was trained on (raw camera stream buffers come in
/// sideways relative to how the phone is held), and packs it into an NCHW
/// float32 tensor normalized to [0, 1]. Downscales first if needed; never
/// upscales beyond [inputSize].
ModelInputTensor buildModelInputTensor(
  img.Image source, {
  required int inputSize,
  int fillGray = 114,
}) {
  final sourceLongSide = math.max(source.width, source.height);
  final scale = sourceLongSide <= inputSize ? 1.0 : inputSize / sourceLongSide;

  final contentWidth = math.max(1, (source.width * scale).round()).clamp(1, inputSize);
  final contentHeight = math.max(1, (source.height * scale).round()).clamp(1, inputSize);

  final content = (contentWidth == source.width && contentHeight == source.height)
      ? source
      : img.copyResize(
          source,
          width: contentWidth,
          height: contentHeight,
          interpolation: img.Interpolation.linear,
        );

  final padX = ((inputSize - contentWidth) / 2).floor();
  final padY = ((inputSize - contentHeight) / 2).floor();

  final canvas = img.Image(width: inputSize, height: inputSize);
  img.fill(canvas, color: img.ColorRgb8(fillGray, fillGray, fillGray));
  img.compositeImage(canvas, content, dstX: padX, dstY: padY);

  // Rotates the same direction RubikDetector._mapModelPointToFrame undoes.
  // Verified empirically against the exported model (not just algebra): Dart's
  // `image` package's copyRotate(angle: X) does not necessarily rotate the same
  // direction as the old native pipeline's Android Matrix.postRotate(X) did for
  // the same angle value - they're different libraries/platforms. angle: 90 here
  // was that wrong carried-over assumption (confirmed via a Python round-trip
  // test against video_coco ground truth: angle:90 gave confidence 0.65 and
  // 0.37 mean normalized error; angle:270 gives confidence 0.88 and 0.035 error).
  final rotated = img.copyRotate(canvas, angle: 270);

  final tensor = Float32List(3 * inputSize * inputSize);
  final planeSize = inputSize * inputSize;
  var idx = 0;
  for (var y = 0; y < inputSize; y++) {
    for (var x = 0; x < inputSize; x++) {
      final pixel = rotated.getPixel(x, y);
      tensor[idx] = pixel.r / 255.0;
      tensor[planeSize + idx] = pixel.g / 255.0;
      tensor[2 * planeSize + idx] = pixel.b / 255.0;
      idx++;
    }
  }

  final contentRgb = Uint8List(contentWidth * contentHeight * 3);
  var rgbIdx = 0;
  for (var y = 0; y < contentHeight; y++) {
    for (var x = 0; x < contentWidth; x++) {
      final pixel = content.getPixel(x, y);
      contentRgb[rgbIdx++] = pixel.r.toInt();
      contentRgb[rgbIdx++] = pixel.g.toInt();
      contentRgb[rgbIdx++] = pixel.b.toInt();
    }
  }

  return ModelInputTensor(
    tensor: tensor,
    letterbox: LetterboxInfo(
      contentWidthFrac: contentWidth / inputSize,
      contentHeightFrac: contentHeight / inputSize,
      padXFrac: padX / inputSize,
      padYFrac: padY / inputSize,
    ),
    contentRgb: contentRgb,
    contentWidth: contentWidth,
    contentHeight: contentHeight,
  );
}

class DetectionResult {
  final String color;
  final double confidence;
  final List<double> bbox; // [x, y, width, height], frame-normalized [0,1]

  DetectionResult({
    required this.color,
    required this.confidence,
    required this.bbox,
  });
}

class KeypointResult {
  final int index;
  final Offset normalized;
  final double score;
  final bool visible;

  const KeypointResult({
    required this.index,
    required this.normalized,
    required this.score,
    required this.visible,
  });
}

class CubePoint3 {
  final double x;
  final double y;
  final double z;

  const CubePoint3(this.x, this.y, this.z);
}

class SolvePnPHookData {
  final List<CubePoint3> objectPoints;
  final List<KeypointResult> imageKeypoints;

  const SolvePnPHookData({
    required this.objectPoints,
    required this.imageKeypoints,
  });

  bool get hasEnoughPoints => imageKeypoints.where((p) => p.visible).length >= 4;
}

class CubePoseResult {
  final DetectionResult detection;
  final Rect roiNormalized;
  final List<KeypointResult> keypoints;
  final SolvePnPHookData solvePnP;
  final int stage1InferenceMs;
  final int stage2InferenceMs;
  final bool stage2Used;
  final String stage2Status;

  const CubePoseResult({
    required this.detection,
    required this.roiNormalized,
    required this.keypoints,
    required this.solvePnP,
    required this.stage1InferenceMs,
    required this.stage2InferenceMs,
    required this.stage2Used,
    required this.stage2Status,
  });

  int get visibleKeypointCount => keypoints.where((k) => k.visible).length;

  List<Offset> get visibleKeypointsNormalized => keypoints
      .where((k) => k.visible)
      .map((k) => k.normalized)
      .toList(growable: false);

  List<Offset> get frontFaceQuadNormalized {
    final front = keypoints.where((k) => k.visible && k.index < 4).toList();
    front.sort((a, b) => a.index.compareTo(b.index));
    return front.map((k) => k.normalized).toList(growable: false);
  }
}

class DetectorDebugFrame {
  final double confidence;
  final bool wasSlow;
  final int inferenceMs;
  final String activeModel;
  final String? lastError;

  const DetectorDebugFrame({
    this.confidence = 0.0,
    this.wasSlow = false,
    this.inferenceMs = 0,
    this.activeModel = '',
    this.lastError,
  });
}

/// Single-stage 8-corner cube pose detector, backed by TensorFlow Lite.
///
/// Loads one YOLO-pose model (trained by
/// `rubik_training/train_cube_pose_8pt.py`, exported to TFLite via
/// `rubik_training/colab_export_tflite.py`) and decodes its raw
/// (1, 29, numAnchors) output - box(4) + confidence(1) + 8 keypoints(3 each,
/// x/y/visibility) per anchor - picking the single highest-confidence anchor
/// (one cube per frame, single class). Runs on the GPU delegate when
/// available (Android), falling back to CPU (XNNPACK) automatically.
class RubikDetector {
  static const String modelPath = 'assets/models/cube_pose_8pt.tflite';

  // Must match the imgsz the mobile model was exported/traced at
  // (train_cube_pose_8pt.py's --mobile-imgsz, 320 by default).
  static const int inputSize = 320;
  static const int keypointCount = 8;
  static const int outputChannels = 5 + keypointCount * 3; // box(4)+conf(1)+8*(x,y,vis)

  static const int inferenceTimeoutMs = 3000;
  static const int slowInferenceMs = 300;

  static const double minDetectionScore = 0.20;
  static const double keypointVisibleThreshold = 0.5;
  static const double minPoseDetectionArea = 0.002;
  static const double maxPoseDetectionArea = 0.85;

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  bool _modelLoaded = false;
  bool _usedGpuDelegate = false;
  Future<void>? _loadFuture;
  DetectorDebugFrame _lastDebugFrame = const DetectorDebugFrame(
    activeModel: modelPath,
  );
  List<double>? _lastStableBbox;

  DetectorDebugFrame get lastDebugFrame => _lastDebugFrame;

  String get currentModelAsset =>
      '$modelPath${_usedGpuDelegate ? ' (gpu)' : ' (cpu)'}';

  Future<void> preloadModel() async {
    if (_loadFuture != null) {
      await _loadFuture;
      return;
    }
    _loadFuture = _ensureModelLoaded();
    await _loadFuture;
  }

  Future<void> _ensureModelLoaded() async {
    if (_modelLoaded) {
      return;
    }

    Interpreter interpreter;
    var usedGpu = false;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final options = InterpreterOptions()..addDelegate(GpuDelegateV2());
        interpreter = await Interpreter.fromAsset(modelPath, options: options);
        usedGpu = true;
      } catch (_) {
        // GPU delegate unavailable on this device (or unsupported op graph
        // fallback failed); retry on CPU (XNNPACK).
        interpreter = await Interpreter.fromAsset(modelPath);
      }
    } else {
      interpreter = await Interpreter.fromAsset(modelPath);
    }

    _interpreter = interpreter;
    _isolateInterpreter = await IsolateInterpreter.create(
      address: interpreter.address,
    );
    _usedGpuDelegate = usedGpu;
    _modelLoaded = true;
  }

  /// Runs the model on a pre-built input tensor (see [buildModelInputTensor]).
  /// [letterbox] must describe how the frame was padded to a square.
  Future<CubePoseResult?> detectCubePoseFromTensor(
    Float32List inputTensor, {
    LetterboxInfo letterbox = LetterboxInfo.identity,
  }) async {
    await preloadModel();
    final isolateInterpreter = _isolateInterpreter!;

    if (isolateInterpreter.state == IsolateInterpreterState.loading) {
      // A previous call hasn't actually finished yet. Drop this frame
      // instead of queuing another inference call on top of it.
      _lastDebugFrame = DetectorDebugFrame(
        activeModel: currentModelAsset,
        lastError: 'busy: previous inference still running',
      );
      return null;
    }

    final numAnchors = _interpreter!.getOutputTensor(0).shape.last;
    final outputBytes = Uint8List(outputChannels * numAnchors * 4);
    // Pass raw bytes, not the Float32List itself: Tensor.getInputShapeIfDifferent
    // only skips its (buggy, for flat typed data) shape-inference for
    // Uint8List/ByteBuffer. A bare Float32List is a List<double> as far as
    // that check is concerned, so it gets shape-inferred as 1-D [N] instead
    // of the model's real [1,3,H,W] and wrongly triggers a tensor resize.
    final inputBytes = inputTensor.buffer.asUint8List(
      inputTensor.offsetInBytes,
      inputTensor.lengthInBytes,
    );

    final stopwatch = Stopwatch()..start();
    try {
      await isolateInterpreter
          .run(inputBytes, outputBytes)
          .timeout(const Duration(milliseconds: inferenceTimeoutMs));
    } catch (error) {
      stopwatch.stop();
      _lastDebugFrame = DetectorDebugFrame(
        activeModel: currentModelAsset,
        inferenceMs: stopwatch.elapsedMilliseconds,
        lastError: error.toString(),
      );
      return null;
    }
    stopwatch.stop();

    final inferenceMs = stopwatch.elapsedMilliseconds;
    final wasSlow = inferenceMs >= slowInferenceMs;
    final raw = outputBytes.buffer.asFloat32List(
      outputBytes.offsetInBytes,
      outputBytes.length ~/ 4,
    );

    final decoded = _decodeOutput(raw, numAnchors, letterbox);
    if (decoded == null) {
      _lastDebugFrame = DetectorDebugFrame(
        activeModel: currentModelAsset,
        inferenceMs: inferenceMs,
        wasSlow: wasSlow,
        lastError: 'unexpected model output length: ${raw.length}',
      );
      return null;
    }

    _lastDebugFrame = DetectorDebugFrame(
      confidence: decoded.detection.confidence,
      activeModel: currentModelAsset,
      inferenceMs: inferenceMs,
      wasSlow: wasSlow,
    );

    if (!_isPlausibleDetection(decoded.detection)) {
      _lastStableBbox = null;
      return null;
    }

    final stabilizedBbox = _stabilizeBBox(
      decoded.detection.bbox,
      decoded.detection.confidence,
    );
    final stabilizedDetection = DetectionResult(
      color: decoded.detection.color,
      confidence: decoded.detection.confidence,
      bbox: stabilizedBbox,
    );

    return CubePoseResult(
      detection: stabilizedDetection,
      roiNormalized: Rect.fromLTWH(
        stabilizedBbox[0],
        stabilizedBbox[1],
        stabilizedBbox[2],
        stabilizedBbox[3],
      ),
      keypoints: decoded.keypoints,
      solvePnP: SolvePnPHookData(
        objectPoints: _cubeObjectPoints,
        imageKeypoints: decoded.keypoints,
      ),
      stage1InferenceMs: inferenceMs,
      stage2InferenceMs: 0,
      stage2Used: true,
      stage2Status: 'ok',
    );
  }

  Future<CubePoseResult?> detectCubePose(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found: $imagePath');
    }
    final decoded = img.decodeImage(await file.readAsBytes());
    if (decoded == null) {
      return null;
    }
    final input = buildModelInputTensor(decoded, inputSize: inputSize);
    return detectCubePoseFromTensor(input.tensor, letterbox: input.letterbox);
  }

  /// Decodes the raw (channels, numAnchors) model output - box(cx,cy,w,h) +
  /// sigmoid confidence + 8*(x,y,sigmoid visibility), all already normalized
  /// to [0,1] - picking the single highest-confidence anchor.
  _DecodedPose? _decodeOutput(
    Float32List raw,
    int numAnchors,
    LetterboxInfo letterbox,
  ) {
    if (numAnchors <= 0 || raw.length != outputChannels * numAnchors) {
      return null;
    }

    var bestIdx = 0;
    var bestConf = raw[4 * numAnchors];
    for (var a = 1; a < numAnchors; a++) {
      final c = raw[4 * numAnchors + a];
      if (c > bestConf) {
        bestConf = c;
        bestIdx = a;
      }
    }

    double channel(int c) => raw[c * numAnchors + bestIdx];

    final cx = channel(0);
    final cy = channel(1);
    final w = channel(2);
    final h = channel(3);
    final left = cx - w / 2.0;
    final top = cy - h / 2.0;

    // Map the four box corners through the rotation/letterbox inverse and
    // re-derive an axis-aligned box, since the 90-degree rotation swaps axes.
    final corners = [
      _mapModelPointToFrame(left, top, letterbox),
      _mapModelPointToFrame(left + w, top, letterbox),
      _mapModelPointToFrame(left + w, top + h, letterbox),
      _mapModelPointToFrame(left, top + h, letterbox),
    ];
    final minX = corners.map((p) => p.dx).reduce(math.min);
    final maxX = corners.map((p) => p.dx).reduce(math.max);
    final minY = corners.map((p) => p.dy).reduce(math.min);
    final maxY = corners.map((p) => p.dy).reduce(math.max);

    final detection = DetectionResult(
      color: 'cube',
      confidence: bestConf.clamp(0.0, 1.0).toDouble(),
      bbox: [minX, minY, (maxX - minX), (maxY - minY)],
    );

    final keypoints = <KeypointResult>[];
    for (var k = 0; k < keypointCount; k++) {
      final base = 5 + k * 3;
      final kx = channel(base);
      final ky = channel(base + 1);
      final kv = channel(base + 2).clamp(0.0, 1.0);
      final mapped = _mapModelPointToFrame(kx, ky, letterbox);
      keypoints.add(
        KeypointResult(
          index: k,
          normalized: mapped,
          score: kv.toDouble(),
          visible: kv >= keypointVisibleThreshold,
        ),
      );
    }

    return _DecodedPose(detection: detection, keypoints: keypoints);
  }

  /// Undoes the rotation applied in [buildModelInputTensor] (`angle: 270`,
  /// to match the model's training orientation), then undoes the letterbox
  /// padding, to recover a coordinate normalized against the original camera
  /// frame. This formula is the true inverse of a 270-degree copyRotate -
  /// verified both algebraically and against the model's actual output.
  Offset _mapModelPointToFrame(double nx, double ny, LetterboxInfo lb) {
    final rotatedX = ny;
    final rotatedY = 1.0 - nx;

    final contentX = rotatedX - lb.padXFrac;
    final contentY = rotatedY - lb.padYFrac;

    final fx = lb.contentWidthFrac > 1e-6 ? contentX / lb.contentWidthFrac : contentX;
    final fy = lb.contentHeightFrac > 1e-6 ? contentY / lb.contentHeightFrac : contentY;

    return Offset(fx.clamp(0.0, 1.0), fy.clamp(0.0, 1.0));
  }

  bool _isPlausibleDetection(DetectionResult detection) {
    if (detection.confidence < minDetectionScore) {
      return false;
    }
    final w = detection.bbox[2].clamp(0.0, 1.0);
    final h = detection.bbox[3].clamp(0.0, 1.0);
    final area = w * h;
    return area >= minPoseDetectionArea && area <= maxPoseDetectionArea;
  }

  List<double> _stabilizeBBox(List<double> current, double confidence) {
    final clean = [
      current[0].clamp(0.0, 1.0),
      current[1].clamp(0.0, 1.0),
      current[2].clamp(0.0, 1.0),
      current[3].clamp(0.0, 1.0),
    ];

    final prev = _lastStableBbox;
    if (prev == null) {
      _lastStableBbox = clean;
      return clean;
    }

    final curArea = math.max(1e-6, clean[2] * clean[3]);
    final prevArea = math.max(1e-6, prev[2] * prev[3]);
    final areaRatio = curArea / prevArea;
    final curCx = clean[0] + clean[2] * 0.5;
    final curCy = clean[1] + clean[3] * 0.5;
    final prevCx = prev[0] + prev[2] * 0.5;
    final prevCy = prev[1] + prev[3] * 0.5;
    final centerDist = math.sqrt(
      math.pow(curCx - prevCx, 2) + math.pow(curCy - prevCy, 2),
    );

    final abruptScaleJump = areaRatio > 2.4 || areaRatio < 0.42;
    final abruptCenterJump = centerDist > 0.28;
    if ((abruptScaleJump || abruptCenterJump) && confidence < 0.45) {
      return prev;
    }

    final alpha = confidence >= 0.6 ? 0.28 : 0.18;
    final smoothed = <double>[];
    for (var i = 0; i < 4; i++) {
      smoothed.add(prev[i] * (1.0 - alpha) + clean[i] * alpha);
    }

    smoothed[2] = smoothed[2].clamp(0.02, 0.95);
    smoothed[3] = smoothed[3].clamp(0.02, 0.95);
    smoothed[0] = smoothed[0].clamp(0.0, 1.0 - smoothed[2]);
    smoothed[1] = smoothed[1].clamp(0.0, 1.0 - smoothed[3]);

    _lastStableBbox = smoothed;
    return smoothed;
  }

  static const List<CubePoint3> _cubeObjectPoints = <CubePoint3>[
    CubePoint3(-0.5, -0.5, 0.5),
    CubePoint3(0.5, -0.5, 0.5),
    CubePoint3(0.5, 0.5, 0.5),
    CubePoint3(-0.5, 0.5, 0.5),
    CubePoint3(-0.5, -0.5, -0.5),
    CubePoint3(0.5, -0.5, -0.5),
    CubePoint3(0.5, 0.5, -0.5),
    CubePoint3(-0.5, 0.5, -0.5),
  ];
}

class _DecodedPose {
  final DetectionResult detection;
  final List<KeypointResult> keypoints;

  const _DecodedPose({required this.detection, required this.keypoints});
}
