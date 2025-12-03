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
  final Map<String, Map<String, bool>> _checklistCategories = {
    'Water & Food': {
      'Drinking water (3-day supply)': false,
      'Non-perishable food': false,
      'Manual can opener': false,
    },
    'Medical': {
      'First aid kit': false,
      'Prescription medications': false,
      'Medical supplies': false,
    },
    'Tools & Supplies': {
      'Flashlight with batteries': false,
      'Battery-powered radio': false,
      'Multi-tool/Swiss knife': false,
      'Emergency whistle': false,
      'Waterproof matches': false,
    },
    'Documents': {
      'Cash and important documents': false,
      'Copies of ID and insurance': false,
      'Local maps': false,
    },
    'Communication': {
      'Fully charged phone': false,
      'Emergency contact list': false,
    },
    'Personal': {
      'Change of clothes': false,
      'Sleeping bag/blanket': false,
      'Personal hygiene items': false,
    },
    'Special Needs': {
      'Infant supplies (if applicable)': false,
      'Pet supplies (if applicable)': false,
    },
  };

  int _selectedTabIndex = 0; // 0 = "All", 1+ = categories
  bool _isChatOpen = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _newItemController = TextEditingController();

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
    _newItemController.dispose();
    super.dispose();
  }

  int get _checkedCount {
    int count = 0;
    _checklistCategories.forEach((category, items) {
      count += items.values.where((v) => v).length;
    });
    return count;
  }

  int get _totalCount {
    int count = 0;
    _checklistCategories.forEach((category, items) {
      count += items.length;
    });
    return count;
  }

  double get _progress => _totalCount > 0 ? _checkedCount / _totalCount : 0.0;

  bool _isCategoryComplete(String category) {
    final items = _checklistCategories[category]!;
    return items.values.every((v) => v);
  }

  int _getCategoryCheckedCount(String category) {
    final items = _checklistCategories[category]!;
    return items.values.where((v) => v).length;
  }

  int _getCategoryTotalCount(String category) {
    return _checklistCategories[category]!.length;
  }

  void _toggleItem(String category, String key) {
    setState(() {
      _checklistCategories[category]![key] = !_checklistCategories[category]![key]!;
    });
  }

  void _showAddItemDialog() {
    if (_selectedTabIndex == 0) return; // Can't add to "All"
    
    final category = _checklistCategories.keys.elementAt(_selectedTabIndex - 1);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Item to $category',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newItemController,
                autofocus: true,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter item name...',
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onSubmitted: (_) {
                  if (_newItemController.text.trim().isNotEmpty) {
                    setState(() {
                      _checklistCategories[category]![_newItemController.text.trim()] = false;
                    });
                    _newItemController.clear();
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _newItemController.clear();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_newItemController.text.trim().isNotEmpty) {
                          setState(() {
                            _checklistCategories[category]![_newItemController.text.trim()] = false;
                          });
                          _newItemController.clear();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Add',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '$_checkedCount/$_totalCount',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _progress == 1.0
                                  ? AppColors.success
                                  : const Color(0xFFFF6E40),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor: isDarkMode
                              ? AppColors.darkBorder
                              : AppColors.lightBorderPrimary,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _progress == 1.0
                                ? AppColors.success
                                : const Color(0xFFFF6E40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _checklistCategories.keys.length + 1, // +1 for "All"
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "All" tab
                        final isSelected = _selectedTabIndex == 0;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedTabIndex = 0),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black87 : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.grid_view_rounded,
                                    size: 16,
                                    color: isSelected ? Colors.white : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'All',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      
                      // Category tabs
                      final category = _checklistCategories.keys.elementAt(index - 1);
                      final isSelected = _selectedTabIndex == index;
                      final isComplete = _isCategoryComplete(category);
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedTabIndex = index),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isComplete ? AppColors.success : Colors.black87)
                                  : (isComplete ? AppColors.success.withOpacity(0.1) : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isComplete && !isSelected 
                                    ? AppColors.success
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isComplete)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: isSelected ? Colors.white : AppColors.success,
                                    ),
                                  ),
                                Text(
                                  category,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isComplete ? AppColors.success : Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Category completion status and add button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        _selectedTabIndex == 0 
                            ? 'All Items' 
                            : _checklistCategories.keys.elementAt(_selectedTabIndex - 1),
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedTabIndex > 0)
                        IconButton(
                          onPressed: _showAddItemDialog,
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.black87,
                          iconSize: 22,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (_selectedTabIndex > 0) const SizedBox(width: 8),
                      Text(
                        _selectedTabIndex == 0
                            ? '$_checkedCount/$_totalCount'
                            : '${_getCategoryCheckedCount(_checklistCategories.keys.elementAt(_selectedTabIndex - 1))}/${_getCategoryTotalCount(_checklistCategories.keys.elementAt(_selectedTabIndex - 1))}',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedTabIndex > 0 && _isCategoryComplete(_checklistCategories.keys.elementAt(_selectedTabIndex - 1))
                              ? AppColors.success
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Checklist items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: _selectedTabIndex == 0
                        ? _checklistCategories.entries.expand((categoryEntry) {
                            return categoryEntry.value.entries.map((itemEntry) {
                              return ChecklistItem(
                                title: itemEntry.key,
                                isChecked: itemEntry.value,
                                onTap: () => _toggleItem(categoryEntry.key, itemEntry.key),
                                onDelete: () {
                                  setState(() {
                                    _checklistCategories[categoryEntry.key]!.remove(itemEntry.key);
                                  });
                                },
                                isDarkMode: isDarkMode,
                              );
                            });
                          }).toList()
                        : _checklistCategories[_checklistCategories.keys.elementAt(_selectedTabIndex - 1)]!
                            .entries
                            .map((entry) {
                          final category = _checklistCategories.keys.elementAt(_selectedTabIndex - 1);
                          return ChecklistItem(
                            title: entry.key,
                            isChecked: entry.value,
                            onTap: () => _toggleItem(category, entry.key),
                            onDelete: () {
                              setState(() {
                                _checklistCategories[category]!.remove(entry.key);
                              });
                            },
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
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () => setState(() => _isChatOpen = true),
                backgroundColor: const Color(0xFFFF6B6B),
                elevation: 8,
                mini: false,
                child: const Icon(Icons.chat_bubble, color: Colors.white, size: 24),
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
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Chat header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDarkMode
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorderPrimary,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.smart_toy,
                                      color: const Color(0xFFFF6B6B),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'BantAI Bayan',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFFF6B6B),
                                            ),
                                          ),
                                          Text(
                                            'Laging Umaalalay',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 11,
                                              color: const Color(0xFFFF6B6B),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: isDarkMode
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorderPrimary,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Ask me anything...',
                                          hintStyle: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _sendMessage,
                                      icon: const Icon(
                                        Icons.send,
                                        color: Color(0xFFFF6B6B),
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.1),
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
