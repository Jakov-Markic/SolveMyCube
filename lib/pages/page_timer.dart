import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class PageTimer extends StatefulWidget {
  const PageTimer({super.key});

  @override
  State<PageTimer> createState() => _PageTimerState();
}

class _PageTimerState extends State<PageTimer> with SingleTickerProviderStateMixin {
  late final Timer _timer;
  late final AnimationController _borderController;

  Duration _elapsed = Duration.zero;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 1),
    );

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_isRunning) {
        setState(() {
          _elapsed += const Duration(milliseconds: 16);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _borderController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _borderController.repeat(); // Starts or resumes rotation
      } else {
        _borderController.stop(); // Pauses rotation
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _elapsed = Duration.zero;
      _borderController.reset(); // Resets animation back to 12 o'clock
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = (duration.inMilliseconds.remainder(1000) / 10).floor().toString().padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _borderController,
                builder: (context, child) {
                  return Container(
                    width: 280,
                    height: 280,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: SweepGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.15),
                          colorScheme.primary.withOpacity(0.15),
                          colorScheme.primary,
                        ],
                        stops: const [0.0, 0.05, 0.95, 1.0],
                        // Subtracts pi/2 to offset starting angle to 12 o'clock (top)
                        transform: GradientRotation(
                          (_borderController.value * 2 * math.pi) - (math.pi / 2),
                        ),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDuration(_elapsed),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 52),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    child: ElevatedButton.icon(
                      onPressed: _toggleTimer,
                      icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(_isRunning ? 'Stop' : 'Start'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: OutlinedButton.icon(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}