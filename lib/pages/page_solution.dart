import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../algorithms/algorithms.dart';
import '../widgets/widgets.dart';

typedef SolverFunction = String Function(List<List<List<Color>>> faces);

/// Solution walkthrough: runs the selected solver against the captured cube,
/// then lets the user step forward/backward through the resulting moves
/// while watching the cube state update at each step.
class PageSolution extends StatefulWidget {
  final List<List<List<Color>>> cubeFaces;
  final String? algorithm;

  const PageSolution({
    super.key,
    required this.cubeFaces,
    this.algorithm,
  });

  @override
  State<PageSolution> createState() => _PageSolutionState();
}

class _PageSolutionState extends State<PageSolution> {
  late final List<List<List<Color>>> _initialFaces;
  List<String> _moves = [];
  late final ValueNotifier<List<int>> _cellsRemainingNotifier;
  String _solverName = 'cfop';
  bool _isLoading = true;
  String? _errorMessage;
  int _currentStep = 0;
  Face _selectedFace = Face.F;

  // Simply map algorithm names to solver functions
  static final Map<String, SolverFunction> _solverMap = {
    'cfop': solveCfop,
    'kociemba': solveKociemba,
    'thistlethwaite': solveThistlethwaite,
  };

  /// Snapshots [PageSolution.cubeFaces] and starts solving in the background.
  @override
  void initState() {
    super.initState();
    _cellsRemainingNotifier = ValueNotifier(List.filled(6, 9));
    _initialFaces = _cloneFaces(widget.cubeFaces);
    _loadSolution();
  }

  /// Builds the step controls, move list, and the cube state preview for
  /// [_currentStep].
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentFaces = _getFacesAtStep(_currentStep);
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
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: const RubiksCube3D(size: 220),
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
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Text(
                  _errorMessage ??
                      (_moves.isEmpty
                          ? 'Already solved!'
                          : (_currentStep == 0
                              ? 'Initial state'
                              : 'Step ${_currentStep} of ${_moves.length}')),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Solver: $_solverName',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              if (!_isLoading && _moves.isNotEmpty)
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
              if (!_isLoading && _moves.isNotEmpty)
                Text(
                  'Current move: ${highlightedMoveIndex >= 0 ? _moves[highlightedMoveIndex] : 'Start'}',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IgnorePointer(
                      child: RubiksGridView(
                        allFaces: currentFaces,
                        selectedFace: _selectedFace,
                        selectedColor: Colors.white,
                        cellsRemainingNotifier: _cellsRemainingNotifier,
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

  // ---------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------

  /// Replays moves `0..step` from [_initialFaces] and returns the resulting
  /// cube state, or the untouched initial state at step 0.
  List<List<List<Color?>>> _getFacesAtStep(int step) {
    if (step == 0 || _moves.isEmpty) {
      return _toNullableFaces(_initialFaces);
    }

    // Apply moves up to the current step
    var currentFaces = _cloneFaces(_initialFaces);
    final cube = RubiksCube(currentFaces);

    for (int i = 0; i < step; i++) {
      cube.executeSequence(_moves[i]);
    }

    return _toNullableFaces(cube.grid);
  }

  /// Resolves the algorithm to use (explicit widget param, else the user's
  /// saved preference), runs its solver against the captured faces, and
  /// parses the resulting move sequence into [_moves].
  Future<void> _loadSolution() async {
    // Get the algorithm name and convert to lowercase
    final rawAlgorithm = widget.algorithm ?? await _loadSelectedAlgorithm();
    final algorithmKey = rawAlgorithm.toLowerCase();

    // Get the solver function from the map
    final solver = _solverMap[algorithmKey] ?? solveCfop;

    // Clone the faces and solve
    final solverFaces = _cloneFaces(widget.cubeFaces);
    final solution = solver(solverFaces);

    // Parse moves
    final moves = solution
        .trim()
        .split(RegExp(r'\s+'))
        .where((move) => move.isNotEmpty)
        .toList();

    setState(() {
      _solverName = rawAlgorithm; // Keep original for display
      _moves = moves;
      _isLoading = false;
      _errorMessage = moves.isEmpty && solution.isNotEmpty ? 'No solution found' : null;
    });
  }

  /// Reads the user's saved solver preference, defaulting to CFOP.
  Future<String> _loadSelectedAlgorithm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('algorithm') ?? 'CFOP';
  }

  /// Deep-copies a `[face][row][col]` color grid.
  List<List<List<Color>>> _cloneFaces(List<List<List<Color>>> faces) {
    return faces
        .map((face) => face.map((row) => row.toList()).toList())
        .toList();
  }

  /// Widens a non-nullable color grid to the nullable form [RubiksGridView]
  /// expects.
  List<List<List<Color?>>> _toNullableFaces(List<List<List<Color>>> faces) {
    return faces
        .map((face) => face.map((row) => row.map<Color?>((cell) => cell).toList()).toList())
        .toList();
  }
}
