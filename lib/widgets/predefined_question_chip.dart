import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../core/theme/theme.dart';

class PredefinedQuestionChip extends StatelessWidget {
  final String question;
  final VoidCallback onTap;

  const PredefinedQuestionChip({
    super.key,
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.lightShadow,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.help_outline,
              color: AppColors.emergencyRed,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.slateGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
