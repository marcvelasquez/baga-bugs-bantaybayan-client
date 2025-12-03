import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../core/theme/colors.dart';
import '../core/theme/theme_provider.dart';
import '../widgets/checklist_item.dart';
import '../widgets/chat_message.dart';

class HandbookScreen extends StatefulWidget {
  const HandbookScreen({super.key});

  @override
  State<HandbookScreen> createState() => _HandbookScreenState();
}

class _HandbookScreenState extends State<HandbookScreen> {
  final Map<String, bool> _checklistItems = {
    // Water & Food
    'Drinking water (3-day supply)': false,
    'Non-perishable food': false,
    'Manual can opener': false,
    // Medical
    'First aid kit': false,
    'Prescription medications': false,
    'Medical supplies': false,
    // Tools & Supplies
    'Flashlight with batteries': false,
    'Battery-powered radio': false,
    'Multi-tool/Swiss knife': false,
    'Emergency whistle': false,
    'Waterproof matches': false,
    // Documents
    'Cash and important documents': false,
    'Copies of ID and insurance': false,
    'Local maps': false,
    // Communication
    'Fully charged phone': false,
    'Emergency contact list': false,
    // Personal
    'Change of clothes': false,
    'Sleeping bag/blanket': false,
    'Personal hygiene items': false,
    // Special Needs
    'Infant supplies (if applicable)': false,
    'Pet supplies (if applicable)': false,
  };

  bool _isChatOpen = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add initial bot message
    _messages.add(
      ChatMessage(
        text:
            'Hello! I\'m your AI assistant. Ask me about flood safety, first aid, evacuation, or typhoon protocols.',
        isBot: true,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  int get _checkedCount => _checklistItems.values.where((v) => v).length;
  int get _totalCount => _checklistItems.length;
  double get _progress => _totalCount > 0 ? _checkedCount / _totalCount : 0.0;

  void _toggleItem(String key) {
    setState(() {
      _checklistItems[key] = !_checklistItems[key]!;
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isBot: false));
    });

    _messageController.clear();

    // Generate bot response based on keywords
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(
          ChatMessage(
            text: _getBotResponse(userMessage.toLowerCase()),
            isBot: true,
          ),
        );
      });
      _scrollToBottom();
    });

    _scrollToBottom();
  }

  String _getBotResponse(String message) {
    if (message.contains('flood') || message.contains('water')) {
      return 'Flood Safety:\n• Move to higher ground immediately\n• Avoid walking/driving through floodwater\n• Turn off utilities if instructed\n• Stay informed via radio/alerts\n• Never touch electrical equipment if wet';
    } else if (message.contains('first aid') || message.contains('injury')) {
      return 'First Aid Basics:\n• Stop bleeding with pressure\n• Clean wounds with clean water\n• Apply bandages properly\n• Monitor for infection\n• Seek medical help for serious injuries';
    } else if (message.contains('evacuation') || message.contains('evacuate')) {
      return 'Evacuation Checklist:\n• Grab your emergency kit\n• Secure your home\n• Follow designated routes\n• Go to nearest evacuation center\n• Inform family of your location\n• Bring important documents';
    } else if (message.contains('typhoon') || message.contains('storm')) {
      return 'Typhoon Safety:\n• Stay indoors away from windows\n• Prepare emergency supplies\n• Charge all devices\n• Fill bathtubs with water\n• Monitor weather updates\n• Evacuate if in danger zone';
    } else {
      return 'I can help with:\n• Flood safety\n• First aid guidance\n• Evacuation procedures\n• Typhoon protocols\n\nWhat would you like to know?';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with progress
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Emergency Checklist',
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '$_checkedCount/$_totalCount',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _progress == 1.0
                                  ? AppColors.success
                                  : theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: isDarkMode
                              ? AppColors.darkBorder
                              : AppColors.lightBorderPrimary,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _progress == 1.0
                                ? AppColors.success
                                : theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Checklist items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: _checklistItems.entries.map((entry) {
                      return ChecklistItem(
                        title: entry.key,
                        isChecked: entry.value,
                        onTap: () => _toggleItem(entry.key),
                        isDarkMode: isDarkMode,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Floating chat button
          if (!_isChatOpen)
            Positioned(
              right: 16,
              bottom: 100, // Above bottom nav
              child: FloatingActionButton(
                onPressed: () => setState(() => _isChatOpen = true),
                backgroundColor: const Color(0xFFFF6B6B),
                elevation: 4,
                child: const Icon(Icons.chat_bubble, color: Colors.white),
              ),
            ),

          // Chat interface
          if (_isChatOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isChatOpen = false),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: GestureDetector(
                      onTap: () {}, // Prevent closing when tapping chat
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 100, 16, 80),
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.1),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowHeavy,
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Chat header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDarkMode
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorderPrimary,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.smart_toy,
                                      color: theme.colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AI Assistant',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Always here to help',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          setState(() => _isChatOpen = false),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                              ),

                              // Messages
                              Flexible(
                                child: ListView.builder(
                                  controller: _chatScrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    return ChatMessageWidget(
                                      message: _messages[index],
                                      isDarkMode: isDarkMode,
                                    );
                                  },
                                ),
                              ),

                              // Input field
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: isDarkMode
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorderPrimary,
                                    ),
                                  ),
                                ),
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
                                          hintText: 'Ask me anything...',
                                          hintStyle: GoogleFonts.montserrat(
                                            fontSize: 15,
                                            color: Colors.grey[500],
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _sendMessage,
                                      icon: Icon(
                                        Icons.send,
                                        color: theme.colorScheme.secondary,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: theme
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
