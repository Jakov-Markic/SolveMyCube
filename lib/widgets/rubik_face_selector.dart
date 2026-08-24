import 'package:flutter/material.dart';
import '../cube_face.dart';

/// Rubik's cube face picker.
class RubikFaceSelector extends StatelessWidget {
  final Face selectedFace;

  /// Called with the tapped face.
  final ValueChanged<Face> onFaceChanged;

  const RubikFaceSelector({
    super.key,
    required this.selectedFace,
    required this.onFaceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: Face.values.map((face) {
        final isActive = face == selectedFace;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            width: 40,
            height: 30,
            child: ElevatedButton(
              onPressed: () => onFaceChanged(face),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                padding: EdgeInsets.zero,
                elevation: isActive ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                face.label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
