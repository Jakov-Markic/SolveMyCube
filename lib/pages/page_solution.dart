import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './page_manual_fill.dart';
import '../algorithms/cfop/cfop.dart';
import '../algorithms/kociemba/kociemba.dart';
import '../algorithms/thistlethwaite/thistlethwaite.dart';

typedef SolverFunction = String Function(List<List<List<Color>>> faces);

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

  // Simply map algorithm names to solver functions
  static final Map<String, SolverFunction> _solverMap = {
    'cfop': solveCfop,
    'kociemba': solveKociemba,
    'thistlethwaite': solveThistlethwaite,
  };

  @override
  void initState() {
    super.initState();
    _cellsRemainingNotifier = ValueNotifier(List.filled(6, 9));
    _initialFaces = _cloneFaces(widget.cubeFaces);
    _loadSolution();
  }

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

  Future<String> _loadSelectedAlgorithm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('algorithm') ?? 'CFOP';
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