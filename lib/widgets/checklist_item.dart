import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Checklist item widget with checkbox toggle
class ChecklistItem extends StatelessWidget {
  final String title;
  final bool isChecked;
  final VoidCallback onTap;
  final bool isDarkMode;

  const ChecklistItem({
    super.key,
    required this.title,
    required this.isChecked,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Checkbox icon
            Icon(
              isChecked ? Icons.check_circle : Icons.circle_outlined,
              color: isChecked
                  ? theme.colorScheme.secondary
                  : theme.iconTheme.color?.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                  color: isChecked
                      ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
