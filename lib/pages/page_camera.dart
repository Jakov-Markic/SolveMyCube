import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../cube_face.dart';
import '../services/detector_service.dart';
import '../services/cube_geometry.dart';
import '../services/face_color_extractor.dart';
import '../services/solve_pnp_service.dart';
import 'page_manual_fill.dart';

// A screen that allows users to take a picture using a given camera.
class PageCamera extends StatefulWidget {
  final CameraDescription camera;

  const PageCamera({super.key, required this.camera});

  @override
  PageCameraState createState() => PageCameraState();
}

class PageCameraState extends State<PageCamera> {
  // Match the model's actual input resolution so we're not encoding/decoding
  // a larger frame than the native side will immediately downscale anyway.
  static const int _detectorLongSide = RubikDetector.inputSize;
  static const double _poseEmaAlpha = 0.22;

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  // Add these new variables
  final RubikDetector _detector = RubikDetector();
  final SolvePnPService _solvePnP = SolvePnPService();
  bool _isProcessing = false;
  String? _detectionResult;
  CubeGeometryResult? _cubeGeometry;
  Size? _lastFrameSize;
  List<DetectionResult> _lastDetections = const [];
  CubePoseResult? _lastPoseResult;
  ModelInputTensor? _lastModelInput;

  // Which face the F/R/U/B/L/D selector currently points at, and the
  // captured (not live-only) scan results per face. This is a manual stand-in
  // for real orientation tracking - see the capture flow for details.
  Face _selectedFace = Face.F;
  final List<List<List<Color?>>> _scannedFaces = List<List<List<Color?>>>.generate(
    6,
    (_) => List<List<Color?>>.generate(3, (_) => List<Color?>.filled(3, null)),
  );
  DateTime? _lastInferenceAt;
  bool _isStreaming = false;
  late final ValueNotifier<List<int>> _cellsRemainingNotifier;
  static const int _maxDetectionHistory = 6;
  final List<DetectionResult> _detectionHistory = <DetectionResult>[];
  DetectorDebugFrame _detectorDebug = const DetectorDebugFrame();
  Duration _lastConversionTime = Duration.zero;
  Duration _lastInferenceTime = Duration.zero;
  int _conversionFailures = 0;
  CubePoseAngles? _lastAngles;

  @override
  void initState() {
    super.initState();
    _detectorDebug = DetectorDebugFrame(activeModel: _detector.currentModelAsset);
    _cellsRemainingNotifier = ValueNotifier(List<int>.filled(6, 9));
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.high,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize().then((_) async {
      if (!mounted) return;
      await _controller.startImageStream(_onCameraFrame);
      if (!mounted) return;
      setState(() {
        _isStreaming = true;
      });
    });
    unawaited(_warmupDetector());
  }

  @override
  void dispose() {
    if (_controller.value.isStreamingImages) {
      _controller.stopImageStream();
    }
    _controller.dispose();
    _cellsRemainingNotifier.dispose();
    super.dispose();
  }

  Future<void> _warmupDetector() async {
    try {
      await _detector.preloadModel();
    } catch (_) {
      // Ignore warmup errors; inference will still attempt on demand.
    }
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (_isProcessing || !_isStreaming) {
      return;
    }

    final now = DateTime.now();
    if (_lastInferenceAt != null &&
        now.difference(_lastInferenceAt!).inMilliseconds < 120) {
      return;
    }
    _lastInferenceAt = now;

    if (_frameLooksDark(image)) {
      _detectorDebug = DetectorDebugFrame(
        activeModel: _detector.currentModelAsset,
        lastError: 'dark-frame-gated',
      );
      _lastDetections = const [];
      _lastPoseResult = null;
      _lastAngles = null;
      if (mounted) {
        setState(() {
          _detectionResult = 'No cube detected';
          _cubeGeometry = null;
        });
      }
      return;
    }

    final conversionStopwatch = Stopwatch()..start();
    final modelInput = await compute(
      _convertSerializedFrameToModelInput,
      _serializeCameraImage(image, targetLongSide: _detectorLongSide),
    );
    conversionStopwatch.stop();
    _lastConversionTime = conversionStopwatch.elapsed;
    if (modelInput.tensor.isEmpty) {
      _conversionFailures += 1;
      _detectorDebug = DetectorDebugFrame(
        activeModel: _detector.currentModelAsset,
        lastError: 'frame conversion failed ($_conversionFailures)',
      );
      if (mounted) {
        setState(() {
          _detectionResult = 'Analyzing live frame...';
        });
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _detectionResult = 'Analyzing live frame...';
    });

    try {
      final inferenceStopwatch = Stopwatch()..start();
      final pose = await _detector.detectCubePoseFromTensor(
        modelInput.tensor,
        letterbox: modelInput.letterbox,
      );
      inferenceStopwatch.stop();
      if (!mounted) return;

      if (pose == null && (_detector.lastDebugFrame.lastError?.startsWith('busy') ?? false)) {
        // Previous native call is still running; this frame was dropped
        // before ever reaching the model. Keep showing the last good result
        // instead of flashing "No cube detected" every time we back off.
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final results = pose == null
          ? const <DetectionResult>[]
          : <DetectionResult>[pose.detection];
        final smoothedPose = _smoothPoseResult(pose);
        final poseForUi = smoothedPose ?? pose;

      final smoothedResults = _smoothDetections(results);
      _lastFrameSize = Size(image.width.toDouble(), image.height.toDouble());
      _lastDetections = smoothedResults;
        _lastPoseResult = poseForUi;
      if (modelInput.contentRgb.isNotEmpty) {
        _lastModelInput = modelInput;
      }

      if (poseForUi != null) {
        _lastAngles = await _solvePnP.estimateAngles(
          pose: poseForUi,
          imageWidth: image.width,
          imageHeight: image.height,
        );
      }

      _detectorDebug = _detector.lastDebugFrame;
      _lastInferenceTime = Duration(
        milliseconds: _detectorDebug.inferenceMs > 0
        ? _detectorDebug.inferenceMs
        : inferenceStopwatch.elapsedMilliseconds,
      );

      if (smoothedResults.isEmpty) {
        setState(() {
          _detectionResult = 'No cube detected';
          _cubeGeometry = null;
          _lastDetections = const [];
          _lastPoseResult = null;
          _lastAngles = null;
          _isProcessing = false;
        });
        return;
      }

      final colorList = smoothedResults
          .map(
            (r) => '${r.color} (${(r.confidence * 100).toStringAsFixed(0)}%)',
          )
          .join(', ');

      setState(() {
        _detectionResult = 'Found: $colorList';
        _cubeGeometry = poseForUi != null
          ? CubeGeometry.fromPoseResult(poseForUi, imageSize: _lastFrameSize)
            : CubeGeometry.fromDetections(
                smoothedResults,
                imageSize: _lastFrameSize,
              );
        _isProcessing = false;
      });
    } catch (e) {
      _detectorDebug = _detector.lastDebugFrame;
      _lastInferenceTime = Duration(
        milliseconds: _detectorDebug.inferenceMs,
      );
      if (!mounted) return;
      setState(() {
        _detectionResult = 'Error: ${e.toString()}';
        _cubeGeometry = null;
        _lastDetections = const [];
        _lastPoseResult = null;
        _lastAngles = null;
        _isProcessing = false;
      });
    }
  }

  List<DetectionResult> _smoothDetections(List<DetectionResult> results) {
    if (results.isEmpty) {
      _detectionHistory.clear();
      return const [];
    }

    final latest = results.first;
    _detectionHistory.add(latest);
    if (_detectionHistory.length > _maxDetectionHistory) {
      _detectionHistory.removeAt(0);
    }

    if (_detectionHistory.length == 1) {
      return [latest];
    }

    final avgLeft = _detectionHistory.fold<double>(0.0, (sum, item) => sum + item.bbox[0]) /
        _detectionHistory.length;
    final avgTop = _detectionHistory.fold<double>(0.0, (sum, item) => sum + item.bbox[1]) /
        _detectionHistory.length;
    final avgWidth = _detectionHistory.fold<double>(0.0, (sum, item) => sum + item.bbox[2]) /
        _detectionHistory.length;
    final avgHeight = _detectionHistory.fold<double>(0.0, (sum, item) => sum + item.bbox[3]) /
        _detectionHistory.length;
    final avgConfidence = _detectionHistory.fold<double>(0.0, (sum, item) => sum + item.confidence) /
        _detectionHistory.length;

    return [
      DetectionResult(
        color: latest.color,
        confidence: avgConfidence,
        bbox: [avgLeft, avgTop, avgWidth, avgHeight],
      ),
    ];
  }

  CubePoseResult? _smoothPoseResult(CubePoseResult? current) {
    if (current == null) {
      return null;
    }

    final prev = _lastPoseResult;
    if (prev == null || !prev.stage2Used || !current.stage2Used) {
      return current;
    }

    final prevRoi = prev.roiNormalized;
    final curRoi = current.roiNormalized;
    final prevArea = (prevRoi.width * prevRoi.height).clamp(1e-6, 1.0);
    final curArea = (curRoi.width * curRoi.height).clamp(1e-6, 1.0);
    final areaRatio = curArea / prevArea;

    if ((areaRatio > 2.2 || areaRatio < 0.45) && current.detection.confidence < 0.55) {
      return prev;
    }

    final blendedRoi = Rect.fromLTWH(
      _lerp(prevRoi.left, curRoi.left, _poseEmaAlpha),
      _lerp(prevRoi.top, curRoi.top, _poseEmaAlpha),
      _lerp(prevRoi.width, curRoi.width, _poseEmaAlpha),
      _lerp(prevRoi.height, curRoi.height, _poseEmaAlpha),
    );

    final smoothedKpts = <KeypointResult>[];
    for (var i = 0; i < current.keypoints.length; i++) {
      final c = current.keypoints[i];
      final p = i < prev.keypoints.length ? prev.keypoints[i] : c;
      final cx = _lerp(p.normalized.dx, c.normalized.dx, _poseEmaAlpha);
      final cy = _lerp(p.normalized.dy, c.normalized.dy, _poseEmaAlpha);
      smoothedKpts.add(
        KeypointResult(
          index: c.index,
          normalized: Offset(cx.clamp(0.0, 1.0), cy.clamp(0.0, 1.0)),
          score: _lerp(p.score, c.score, 0.25),
          visible: c.visible || p.visible,
        ),
      );
    }

    final smoothedDetection = DetectionResult(
      color: current.detection.color,
      confidence: _lerp(prev.detection.confidence, current.detection.confidence, 0.2),
      bbox: [
        blendedRoi.left,
        blendedRoi.top,
        blendedRoi.width,
        blendedRoi.height,
      ],
    );

    return CubePoseResult(
      detection: smoothedDetection,
      roiNormalized: blendedRoi,
      keypoints: smoothedKpts,
      solvePnP: SolvePnPHookData(
        objectPoints: current.solvePnP.objectPoints,
        imageKeypoints: smoothedKpts,
      ),
      stage1InferenceMs: current.stage1InferenceMs,
      stage2InferenceMs: current.stage2InferenceMs,
      stage2Used: current.stage2Used,
      stage2Status: '${current.stage2Status}|smoothed',
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Map<String, Object> _serializeCameraImage(
    CameraImage image, {
    required int targetLongSide,
  }) {
    final planes = image.planes
        .map(
          (plane) => <String, Object>{
            'bytes': plane.bytes,
            'bytesPerRow': plane.bytesPerRow,
            'bytesPerPixel': plane.bytesPerPixel ?? 1,
          },
        )
        .toList(growable: false);

    return <String, Object>{
      'width': image.width,
      'height': image.height,
      'isBgra': image.format.group == ImageFormatGroup.bgra8888,
      'targetLongSide': targetLongSide,
      'planes': planes,
    };
  }

  bool _frameLooksDark(CameraImage image) {
    if (image.planes.isEmpty) {
      return false;
    }

    final isBgra = image.format.group == ImageFormatGroup.bgra8888;
    final brightnessSamples = <double>[];

    if (isBgra) {
      final plane = image.planes.first;
      final bytes = plane.bytes;
      for (var i = 0; i + 3 < bytes.length; i += 64) {
        final b = bytes[i].toDouble();
        final g = bytes[i + 1].toDouble();
        final r = bytes[i + 2].toDouble();
        brightnessSamples.add((0.114 * b) + (0.587 * g) + (0.299 * r));
      }
    } else {
      final yPlane = image.planes.first;
      final bytes = yPlane.bytes;
      for (var i = 0; i < bytes.length; i += 32) {
        brightnessSamples.add(bytes[i].toDouble());
      }
    }

    if (brightnessSamples.isEmpty) {
      return false;
    }

    var sum = 0.0;
    var sumSq = 0.0;
    for (final v in brightnessSamples) {
      sum += v;
      sumSq += v * v;
    }
    final mean = sum / brightnessSamples.length;
    final variance = (sumSq / brightnessSamples.length) - (mean * mean);

    return mean < 18.0 && variance < 40.0;
  }

  /// Samples sticker colors from the last frame a pose was detected in, using
  /// the same geometry currently drawn on screen (so what you see is what
  /// gets captured), and writes them into the currently-selected face slot.
  ///
  /// This is a manual stand-in for real orientation tracking: the user tells
  /// the app which face is being shown via the F/R/U/B/L/D selector, rather
  /// than the app inferring it from cube rotation. See the face-color
  /// extraction conversation for the planned auto-tracking design.
  void _captureCurrentFace() {
    final pose = _lastPoseResult;
    final modelInput = _lastModelInput;
    if (pose == null || modelInput == null || modelInput.contentRgb.isEmpty) {
      setState(() {
        _detectionResult = 'No cube in view to capture';
      });
      return;
    }

    final captureGeometry = CubeGeometry.fromPoseResult(
      pose,
      imageSize: Size(
        modelInput.contentWidth.toDouble(),
        modelInput.contentHeight.toDouble(),
      ),
    );
    if (captureGeometry.outline.length != 4) {
      setState(() {
        _detectionResult = 'Not enough visible corners to capture this face';
      });
      return;
    }

    final contentImage = img.Image.fromBytes(
      width: modelInput.contentWidth,
      height: modelInput.contentHeight,
      bytes: modelInput.contentRgb.buffer,
      numChannels: 3,
      order: img.ChannelOrder.rgb,
    );

    final extracted = FaceColorExtractor.extractClassified(
      contentImage,
      captureGeometry.outline,
    );

    setState(() {
      _scannedFaces[_selectedFace.index] = extracted;
      _detectionResult = 'Captured face ${_selectedFace.label}';
    });
  }

  Future<void> _openManualFill() async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            PageManualFill(initialCubeFaces: _scannedFaces),
      ),
    );
  }

  Widget _buildCameraBackground() {
    final previewSize = _controller.value.previewSize;
    if (previewSize == null) {
      return const SizedBox.expand();
    }

    return FittedBox(
      fit: BoxFit.cover,
      alignment: Alignment.center,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(_controller),
      ),
    );
  }

  String _detectionSummary() {
    if (_lastDetections.isEmpty) {
      return 'AI detections: 0';
    }

    final best = _lastDetections
        .map((d) => d.confidence)
        .fold<double>(0, (previous, next) => next > previous ? next : previous);
    final pnpReady = _lastPoseResult?.solvePnP.hasEnoughPoints == true;
    final stage2Ms = _lastPoseResult?.stage2InferenceMs ?? 0;
    final stage2Used = _lastPoseResult?.stage2Used == true;
    final visibleCount = _lastPoseResult?.visibleKeypointCount ?? 0;
    return 'AI detections: ${_lastDetections.length}  best ${(best * 100).toStringAsFixed(0)}%  '
      'stage2 ${stage2Used ? 'on' : 'fallback'} ${stage2Ms}ms  '
      'kpt $visibleCount/8  pnp ${pnpReady ? 'ready' : 'pending'}';
  }

  String _debugSummary() {
    final confidence = (_detectorDebug.confidence * 100).toStringAsFixed(0);
    final convertMs = _lastConversionTime.inMilliseconds;
    final inferMs = _lastInferenceTime.inMilliseconds;
    final activeModel = _detectorDebug.activeModel.isEmpty
      ? 'n/a'
      : _detectorDebug.activeModel.split('/').last;
    final slowTag = _detectorDebug.wasSlow ? 'SLOW' : 'OK';
    final poseStatus = _lastPoseResult?.stage2Status ?? 'no-detection';
    final angleText = _lastAngles == null
      ? 'angles n/a'
      : 'angles r${_lastAngles!.roll.toStringAsFixed(2)} '
        'p${_lastAngles!.pitch.toStringAsFixed(2)} '
        'y${_lastAngles!.yaw.toStringAsFixed(2)} '
        '${_lastAngles!.solvedByNative ? 'native' : 'fallback'}';
    final errorText = _detectorDebug.lastError == null
        ? ''
        : '\nerr ${_detectorDebug.lastError}';
    return 'confidence $confidence%  convert ${convertMs}ms  infer ${inferMs}ms  $slowTag\n'
      'model $activeModel  $poseStatus\n$angleText$errorText';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Rubik\'s Cube'),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(child: _buildCameraBackground()),
                if (_cubeGeometry != null && _lastFrameSize != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: CubeGeometryPainter(
                          geometry: _cubeGeometry!,
                          sourceSize: _lastFrameSize!,
                          rotationQuarterTurns: 1,
                          detections: _lastDetections,
                          primaryColor: Theme.of(context).colorScheme.primary,
                          secondaryColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                if (_isStreaming)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.videocam, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Live',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_detectionResult != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _detectionResult!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_cubeGeometry != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _cubeGeometry!.summary,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _detectionSummary(),
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  _debugSummary(),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                margin: EdgeInsets.zero,
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Scanned face: ${_selectedFace.label}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          IgnorePointer(
                                            child: RubiksGridView(
                                              allFaces: _scannedFaces,
                                              selectedFace: _selectedFace,
                                              selectedColor: Colors.grey,
                                              cellsRemainingNotifier:
                                                  _cellsRemainingNotifier,
                                              isRubikComplete: (_) {},
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          RubikFaceSelector(
                                            selectedFace: _selectedFace,
                                            onFaceChanged: (face) => setState(() {
                                              _selectedFace = face;
                                            }),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: FloatingActionButton(
                                    heroTag: 'capture-face',
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onSecondary,
                                    onPressed: _lastPoseResult != null
                                        ? _captureCurrentFace
                                        : null,
                                    child: const Icon(Icons.camera_alt),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: FloatingActionButton(
                                    heroTag: 'switch-to-manual',
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    onPressed: _openManualFill,
                                    child: const Icon(Icons.switch_camera),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final String? detectionResult; // Add this parameter

  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    this.detectionResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection Result')),
      body: Column(
        children: [
          Expanded(child: Image.file(File(imagePath))),
          // Show detection results
          if (detectionResult != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Results:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detectionResult!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

ModelInputTensor _convertSerializedFrameToModelInput(Map<String, Object> frame) {
  try {
    final sourceWidth = frame['width']! as int;
    final sourceHeight = frame['height']! as int;
    final targetLongSide = frame['targetLongSide']! as int;
    final isBgra = frame['isBgra']! as bool;
    final planes = frame['planes']! as List<Object>;

    final sourceLongSide =
        sourceWidth >= sourceHeight ? sourceWidth : sourceHeight;
    final scale = sourceLongSide <= targetLongSide
        ? 1.0
        : targetLongSide / sourceLongSide;
    final int width = (sourceWidth * scale).round().clamp(1, sourceWidth);
    final int height =
      (sourceHeight * scale).round().clamp(1, sourceHeight);

    final imgImage = img.Image(width: width, height: height);

    if (isBgra) {
      final plane = planes.first as Map<String, Object>;
      final bytes = plane['bytes']! as Uint8List;
      final bytesPerRow = plane['bytesPerRow']! as int;
      final bytesPerPixel = plane['bytesPerPixel']! as int;

      for (var y = 0; y < height; y++) {
        final sourceY = ((y * sourceHeight) / height).floor();
        for (var x = 0; x < width; x++) {
          final sourceX = ((x * sourceWidth) / width).floor();
          final index = (sourceY * bytesPerRow) + (sourceX * bytesPerPixel);
          final b = bytes[index];
          final g = bytes[index + 1];
          final r = bytes[index + 2];
          imgImage.setPixelRgb(x, y, r, g, b);
        }
      }
    } else {
      if (planes.length < 2) {
        return ModelInputTensor(
          tensor: Float32List(0),
          letterbox: LetterboxInfo.identity,
          contentRgb: Uint8List(0),
          contentWidth: 0,
          contentHeight: 0,
        );
      }

      final yPlane = planes[0] as Map<String, Object>;
      final uvPlane = planes[1] as Map<String, Object>;

      final yBytes = yPlane['bytes']! as Uint8List;
      final yRowStride = yPlane['bytesPerRow']! as int;
      final uvBytes = uvPlane['bytes']! as Uint8List;
      final uvRowStride = uvPlane['bytesPerRow']! as int;
      final uvPixelStride = uvPlane['bytesPerPixel']! as int;
      final hasSeparateUV = planes.length >= 3;
        final vPlane = hasSeparateUV ? planes[2] as Map<String, Object> : null;
      final uBytes = hasSeparateUV
          ? (planes[1] as Map<String, Object>)['bytes']! as Uint8List
          : uvBytes;
      final vBytes = hasSeparateUV
          ? vPlane!['bytes']! as Uint8List
          : uvBytes;
      final separateUvRowStride = hasSeparateUV
          ? (planes[1] as Map<String, Object>)['bytesPerRow']! as int
          : uvRowStride;
      final separateUvPixelStride = hasSeparateUV
          ? (planes[1] as Map<String, Object>)['bytesPerPixel']! as int
          : uvPixelStride;
        final vUvRowStride = hasSeparateUV
          ? vPlane!['bytesPerRow']! as int
          : uvRowStride;
        final vUvPixelStride = hasSeparateUV
          ? vPlane!['bytesPerPixel']! as int
          : uvPixelStride;

      for (var y = 0; y < height; y++) {
        final sourceY = ((y * sourceHeight) / height).floor();
        final uvY = sourceY >> 1;
        for (var x = 0; x < width; x++) {
          final sourceX = ((x * sourceWidth) / width).floor();
          final yIndex = (sourceY * yRowStride) + sourceX;
          final uvX = sourceX >> 1;
          final uvIndex = (uvY * uvRowStride) + (uvX * uvPixelStride);

          final yValue = yBytes[yIndex];
          int uValue;
          int vValue;
          if (hasSeparateUV) {
            final uIndex =
                (uvY * separateUvRowStride) + (uvX * separateUvPixelStride);
            final vIndex = (uvY * vUvRowStride) + (uvX * vUvPixelStride);
            uValue = uBytes[uIndex];
            vValue = vBytes[vIndex];
          } else {
            // Common NV21/NV12 two-plane layout: interleaved UV or VU.
            final first = uvBytes[uvIndex];
            final second = uvBytes[(uvIndex + 1).clamp(0, uvBytes.length - 1)];
            // Heuristic: Android CameraX usually provides NV21 (VU order).
            vValue = first;
            uValue = second;
          }

          final c = yValue - 16;
          final d = uValue - 128;
          final e = vValue - 128;

          final r = _clampToByte((298 * c + 409 * e + 128) >> 8);
          final g = _clampToByte((298 * c - 100 * d - 208 * e + 128) >> 8);
          final b = _clampToByte((298 * c + 516 * d + 128) >> 8);

          imgImage.setPixelRgb(x, y, r, g, b);
        }
      }
    }

    return buildModelInputTensor(imgImage, inputSize: targetLongSide);
  } catch (_) {
    return ModelInputTensor(
      tensor: Float32List(0),
      letterbox: LetterboxInfo.identity,
      contentRgb: Uint8List(0),
      contentWidth: 0,
      contentHeight: 0,
    );
  }
}

int _clampToByte(int value) {
  if (value < 0) return 0;
  if (value > 255) return 255;
  return value;
}
