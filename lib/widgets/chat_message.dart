import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// Chat message model
class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isBot, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

/// Chat message bubble widget
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isDarkMode;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBot = message.isBot;

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(
          left: isBot ? 0 : 48,
          right: isBot ? 48 : 0,
          bottom: 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bot icon (only for bot messages)
            if (isBot) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy,
                  size: 20,
                  color: isDarkMode
                      ? AppColors.darkBackgroundDeep
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Message bubble
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isBot
                      ? (isDarkMode
                            ? AppColors.darkBackgroundElevated
                            : AppColors.lightBackgroundTertiary)
                      : theme.colorScheme.secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isBot ? 4 : 16),
                    topRight: Radius.circular(isBot ? 16 : 4),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isBot
                        ? theme.textTheme.bodyMedium?.color
                        : (isDarkMode
                              ? AppColors.darkBackgroundDeep
                              : AppColors.lightTextPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
