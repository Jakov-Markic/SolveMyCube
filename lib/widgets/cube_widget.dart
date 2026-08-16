import 'package:flutter/material.dart';
import '../pages/page_cube.dart';

/// Cube sizes the solver actually supports right now. Anything else still
/// shows up in the grid (so people know it's coming) but is dimmed and
/// bounces the user with a toast instead of opening [PageCube].
const Set<String> kAvailableCubeSizes = {'3x3'};

/// A tappable tile on the home grid representing one cube size.
///
/// Opens [PageCube] for [title] when tapped, unless [title] isn't in
/// [kAvailableCubeSizes] yet, in which case it shows a "not available" toast.
class CubeWidget extends StatefulWidget {
  final String title;

  const CubeWidget(this.title, {super.key});

  @override
  State<CubeWidget> createState() => _CubeWidgetState();
}

class _CubeWidgetState extends State<CubeWidget> {
  /// Builds the gradient tile with its size label.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Opacity(
        opacity: _isAvailable ? 1.0 : 0.4,
        child: Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: const Alignment(0.8, 1),
              colors: <Color>[
                Theme.of(context).colorScheme.primary.withOpacity(0.55),
                Theme.of(context).colorScheme.secondary.withOpacity(0.95),
              ],
            ),
          ),
          child: ElevatedButton(
            onPressed: () => _handleTap(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------

  /// Whether [title] is one of the currently supported cube sizes.
  bool get _isAvailable => kAvailableCubeSizes.contains(widget.title);

  /// Opens [PageCube] for this tile's size, or shows an unavailable toast.
  void _handleTap(BuildContext context) {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.title} is not currently available.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PageCube(title: widget.title),
      ),
    );
  }
}
