import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'detector_service.dart';

class CubePoseAngles {
  final double roll;
  final double pitch;
  final double yaw;
  final bool solvedByNative;

  const CubePoseAngles({
    required this.roll,
    required this.pitch,
    required this.yaw,
    required this.solvedByNative,
  });

  CubePoseAngles lerp(CubePoseAngles other, double t) {
    return CubePoseAngles(
      roll: roll + (other.roll - roll) * t,
      pitch: pitch + (other.pitch - pitch) * t,
      yaw: yaw + (other.yaw - yaw) * t,
      solvedByNative: solvedByNative || other.solvedByNative,
    );
  }
}

class SolvePnPService {
  static const MethodChannel _channel = MethodChannel('solve_my_cube/pnp');
  static const double _smoothing = 0.22;

  CubePoseAngles? _last;

  Future<CubePoseAngles?> estimateAngles({
    required CubePoseResult pose,
    required int imageWidth,
    required int imageHeight,
  }) async {
    if (!pose.solvePnP.hasEnoughPoints) {
      return _last;
    }

    final visible = pose.solvePnP.imageKeypoints.where((k) => k.visible).toList();
    final objectPoints = <List<double>>[];
    final imagePoints = <List<double>>[];

    for (final k in visible) {
      if (k.index < 0 || k.index >= pose.solvePnP.objectPoints.length) {
        continue;
      }
      final p3 = pose.solvePnP.objectPoints[k.index];
      objectPoints.add([p3.x, p3.y, p3.z]);
      imagePoints.add([
        k.normalized.dx * imageWidth,
        k.normalized.dy * imageHeight,
      ]);
    }

    if (objectPoints.length < 4 || imagePoints.length < 4) {
      return _last;
    }

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('solvePnP', {
        'objectPoints': objectPoints,
        'imagePoints': imagePoints,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
      });

      if (result == null) {
        return _last;
      }

      final roll = (result['roll'] as num?)?.toDouble();
      final pitch = (result['pitch'] as num?)?.toDouble();
      final yaw = (result['yaw'] as num?)?.toDouble();
      if (roll == null || pitch == null || yaw == null) {
        return _last;
      }

      final current = CubePoseAngles(
        roll: roll,
        pitch: pitch,
        yaw: yaw,
        solvedByNative: true,
      );

      if (_last == null) {
        _last = current;
      } else {
        _last = _last!.lerp(current, _smoothing);
      }
      return _last;
    } on MissingPluginException {
      return _fallbackFrom2DPoints(imagePoints, imageWidth, imageHeight);
    } on PlatformException {
      return _fallbackFrom2DPoints(imagePoints, imageWidth, imageHeight);
    }
  }

  CubePoseAngles _fallbackFrom2DPoints(
    List<List<double>> imagePoints,
    int imageWidth,
    int imageHeight,
  ) {
    if (imagePoints.length < 4) {
      return _last ??
          const CubePoseAngles(
            roll: 0,
            pitch: 0,
            yaw: 0,
            solvedByNative: false,
          );
    }

    double meanX = 0;
    double meanY = 0;
    for (final p in imagePoints) {
      meanX += p[0];
      meanY += p[1];
    }
    meanX /= imagePoints.length;
    meanY /= imagePoints.length;

    var vx = 0.0;
    var vy = 0.0;
    for (final p in imagePoints) {
      vx += (p[0] - meanX) * (p[0] - meanX);
      vy += (p[1] - meanY) * (p[1] - meanY);
    }

    final normX = ((meanX / imageWidth) - 0.5).clamp(-0.5, 0.5);
    final normY = ((meanY / imageHeight) - 0.5).clamp(-0.5, 0.5);
    final pitch = -normY * (math.pi / 2.5);
    final yaw = normX * (math.pi / 2.5);
    final roll = math.atan2(vy, vx + 1e-6) - (math.pi / 4.0);

    final current = CubePoseAngles(
      roll: roll,
      pitch: pitch,
      yaw: yaw,
      solvedByNative: false,
    );

    if (_last == null) {
      _last = current;
    } else {
      _last = _last!.lerp(current, _smoothing);
    }
    return _last!;
  }
}
