import 'package:flutter/material.dart';
import './page_manual_fill.dart';
import '../algorithms/cfop/cfop.dart';

class PageSolution extends StatefulWidget {
  final List<List<List<Color>>> cubeFaces;

  const PageSolution({
    super.key,
    required this.cubeFaces,
  });

  @override
  State<PageSolution> createState() => _PageSolutionState();
}

class _PageSolutionState extends State<PageSolution> {
  late final List<List<List<Color>>> _initialFaces;
  late final List<String> _moves;
  late final List<List<List<List<Color?>>>> _stepFaces;
  late final ValueNotifier<List<int>> _cellsRemainingNotifier;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _cellsRemainingNotifier = ValueNotifier(List.filled(6, 9));
    _initialFaces = _cloneFaces(widget.cubeFaces);
    final solverFaces = _cloneFaces(widget.cubeFaces);
    final solution = solveCfop(solverFaces);
    _moves = solution
        .trim()
        .split(RegExp(r'\s+'))
        .where((move) => move.isNotEmpty)
        .toList();
    _stepFaces = _buildStepFaces(_initialFaces, _moves);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentFaces = _stepFaces.isNotEmpty ? _stepFaces[_currentStep] : _toNullableFaces(_initialFaces);
    final highlightedMoveIndex = _currentStep > 0 ? _currentStep - 1 : -1;

    return Scaffold(
      appBar: AppBar(title: const Text('Solution')),
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Solution preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _currentStep > 0
                        ? () => setState(() => _currentStep--)
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _currentStep < _moves.length
                        ? () => setState(() => _currentStep++)
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _moves.isEmpty
                    ? 'Already solved!'
                    : (_currentStep == 0
                        ? 'Initial state'
                        : 'Step ${_currentStep} of ${_moves.length}'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_moves.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_moves.length, (index) {
                    final isCurrent = index == highlightedMoveIndex;
                    return Text(
                      _moves[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 16),
              if (_moves.isNotEmpty)
                Text(
                  'Current move: ${highlightedMoveIndex >= 0 ? _moves[highlightedMoveIndex] : 'Start'}',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 20),
              IgnorePointer(
                child: Center(
                  child: RubiksFace(
                    selectedColor: Colors.white,
                    allFaces: currentFaces,
                    cellsRemainingNotifier: _cellsRemainingNotifier,
                    isRubikComplete: (_) {},
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_moves.isNotEmpty)
                Text(
                  _currentStep == 0
                      ? 'Initial cube state'
                      : 'Cube state after move $_currentStep',
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<List<List<List<Color?>>>> _buildStepFaces(List<List<List<Color>>> initialFaces, List<String> moves) {
    final states = <List<List<List<Color?>>>>[];
    var currentFaces = _cloneFaces(initialFaces);
    states.add(_toNullableFaces(currentFaces));

    for (final move in moves) {
      final cube = RubiksCube(_cloneFaces(currentFaces));
      cube.executeSequence(move);
      currentFaces = cube.grid;
      states.add(_toNullableFaces(currentFaces));
    }

    return states;
  }

  List<List<List<Color>>> _cloneFaces(List<List<List<Color>>> faces) {
    return faces
        .map((face) => face.map((row) => row.toList()).toList())
        .toList();
  }

  List<List<List<Color?>>> _toNullableFaces(List<List<List<Color>>> faces) {
    return faces
        .map((face) => face.map((row) => row.map<Color?>((cell) => cell).toList()).toList())
        .toList();
  }
}
