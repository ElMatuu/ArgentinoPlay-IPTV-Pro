import 'package:flutter/material.dart';

/// A button with a high-contrast focus outline for Android TV remotes.
///
/// The button remains keyboard-focusable and uses Flutter's normal focus
/// traversal, so D-pad/Tab navigation is not intercepted by the player.
class TvFocusButton extends StatelessWidget {
  const TvFocusButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.autofocus = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      autofocus: autofocus,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          final focused = states.contains(WidgetState.focused);
          return BorderSide(
            color: focused ? colorScheme.primary : colorScheme.outline,
            width: focused ? 3 : 1,
          );
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.18);
          }
          return null;
        }),
      ),
    );
  }
}
