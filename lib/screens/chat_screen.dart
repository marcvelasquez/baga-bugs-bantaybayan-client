import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../core/theme/theme.dart';
import '../widgets/predefined_question_chip.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _predefinedQuestions = [
    'What should I do during a flood?',
    'Where is the nearest evacuation center?',
    'How to perform first aid?',
    'What to pack for evacuation?',
    'How to purify water?',
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text:
            'Hello! I\'m your emergency assistance bot. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      // Add user message
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate bot response
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _messages.add(
          ChatMessage(
            text: _getBotResponse(text),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  String _getBotResponse(String question) {
    if (question.toLowerCase().contains('flood')) {
      return 'During a flood:\n\n1. Move to higher ground immediately\n2. Avoid walking or driving through flood waters\n3. Stay away from power lines and electrical wires\n4. Listen to emergency broadcasts\n5. If trapped, go to the highest level of the building';
    } else if (question.toLowerCase().contains('evacuation center')) {
      return 'Nearest evacuation centers:\n\n1. Barangay Hall - 2.3 km away\n2. Community Center - 3.1 km away\n3. High School Gymnasium - 4.5 km away\n\nTap on Map view to see locations.';
    } else if (question.toLowerCase().contains('first aid')) {
      return 'Basic first aid steps:\n\n1. Check the scene for safety\n2. Call for emergency help\n3. Check for breathing and pulse\n4. Control bleeding with direct pressure\n5. Treat for shock if needed\n\nRefer to the Handbook for detailed instructions.';
    } else if (question.toLowerCase().contains('pack')) {
      return 'Emergency evacuation kit:\n\n✓ Water (3-day supply)\n✓ Non-perishable food\n✓ First aid kit\n✓ Flashlight and batteries\n✓ Important documents\n✓ Medications\n✓ Cash\n✓ Phone charger';
    } else if (question.toLowerCase().contains('water') ||
        question.toLowerCase().contains('purify')) {
      return 'Water purification methods:\n\n1. Boiling (most reliable) - 1 minute rolling boil\n2. Water purification tablets\n3. Bleach (2 drops per liter)\n4. Portable water filter\n\nAlways use the safest method available.';
    } else {
      return 'I understand you need help. Please check the Smart Handbook for detailed information, or select one of the quick questions above.';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.emergencyRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.support_agent,
                color: AppColors.emergencyRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Assistant',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Always available',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Predefined Questions
          if (_messages.length <= 2)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Questions', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  ..._predefinedQuestions.map(
                    (question) => PredefinedQuestionChip(
                      question: question,
                      onTap: () => _sendMessage(question),
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 15,
                          color: Colors.grey[500],
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.lightShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: AppColors.surfaceWhite,
                      ),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppColors.emergencyRed
              : AppColors.surfaceWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          boxShadow: AppTheme.lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: message.isUser
                    ? AppColors.surfaceWhite
                    : AppColors.textOnLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: AppTextStyles.labelSmall.copyWith(
                color: message.isUser
                    ? AppColors.surfaceWhite.withOpacity(0.7)
                    : AppColors.slateGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
