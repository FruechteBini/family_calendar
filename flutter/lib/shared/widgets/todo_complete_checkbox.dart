import 'package:flutter/material.dart';

/// Checkbox zum Abhaken von Todos mit mindestens 48×48 dp Bedienfläche und
/// vergrößerter Darstellung (Touchscreens).
class TodoCompleteCheckbox extends StatelessWidget {
  const TodoCompleteCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  static const double _tapSide = 48;
  static const double _visualScale = 1.38;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: 'Erledigt',
      child: SizedBox(
        width: _tapSide,
        height: _tapSide,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onChanged(!value),
            child: Center(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: _visualScale,
                    alignment: Alignment.center,
                    child: Checkbox(
                      value: value,
                      onChanged: onChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
