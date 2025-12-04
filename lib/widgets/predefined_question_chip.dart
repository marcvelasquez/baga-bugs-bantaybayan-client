import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2234),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: AppColors.emergencyRed,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                question,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white60,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
