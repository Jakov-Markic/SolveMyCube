import 'package:flutter/material.dart';

/// App settings: theme, font, and solve-algorithm preference, each
/// persisted via the callbacks passed in from [MainApp].
class PageSettings extends StatefulWidget {
  final ThemeMode themeMode;
  final String selectedFontFamily;
  final String selectedAlgorithm;
  final bool debugMode;
  final Future<void> Function(ThemeMode) onThemeModeChanged;
  final Future<void> Function(String) onFontFamilyChanged;
  final Future<void> Function(String) onAlgorithmChanged;
  final Future<void> Function(bool) onDebugModeChanged;

  const PageSettings({
    super.key,
    required this.themeMode,
    required this.selectedFontFamily,
    required this.selectedAlgorithm,
    required this.debugMode,
    required this.onThemeModeChanged,
    required this.onFontFamilyChanged,
    required this.onAlgorithmChanged,
    required this.onDebugModeChanged,
  });

  @override
  State<PageSettings> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  final List<String> _fontFamilies = ['Roboto', 'Courier', 'Times New Roman', 'sans-serif'];
  final List<String> _algorithms = ['CFOP', 'Kociemba', 'Thistlethwaite'];

  // Only CFOP is implemented right now; the others are listed so people know
  // they're coming, but picking one just bounces with a toast.
  static const Set<String> _availableAlgorithms = {'CFOP'};

  /// Builds the theme/font/algorithm settings card and a summary card below it.
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Dark mode'),
                subtitle: const Text('Switch between light and dark themes.'),
                value: widget.themeMode == ThemeMode.dark,
                onChanged: (value) async {
                  await widget.onThemeModeChanged(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Font family'),
                subtitle: Text('Current font: ${widget.selectedFontFamily}'),
                trailing: DropdownButton<String>(
                  value: widget.selectedFontFamily,
                  items: _fontFamilies
                      .map(
                        (family) => DropdownMenuItem(
                          value: family,
                          child: Text(family),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      await widget.onFontFamilyChanged(value);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Solve algorithm'),
                subtitle: const Text('Choose the solver used for cube solving.'),
                trailing: DropdownButton<String>(
                  value: widget.selectedAlgorithm,
                  items: _algorithms
                      .map(
                        (algorithm) => DropdownMenuItem(
                          value: algorithm,
                          child: Opacity(
                            opacity: _availableAlgorithms.contains(algorithm) ? 1.0 : 0.4,
                            child: Text(algorithm),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    if (!_availableAlgorithms.contains(value)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$value is not currently available.')),
                      );
                      return;
                    }
                    await widget.onAlgorithmChanged(value);
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Camera debug info'),
                subtitle: const Text('Show detector/pose debug text on the camera screen.'),
                value: widget.debugMode,
                onChanged: (value) async {
                  await widget.onDebugModeChanged(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current selection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Theme: ${widget.themeMode == ThemeMode.dark ? 'Dark' : 'Light'}'),
                Text('Font: ${widget.selectedFontFamily}'),
                Text('Algorithm: ${widget.selectedAlgorithm}'),
                Text('Camera debug info: ${widget.debugMode ? 'On' : 'Off'}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}