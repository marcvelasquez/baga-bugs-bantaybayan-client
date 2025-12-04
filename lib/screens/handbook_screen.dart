import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../core/theme/colors.dart';
import '../core/theme/theme_provider.dart';
import '../widgets/chat_message.dart';

class HandbookScreen extends StatefulWidget {
  const HandbookScreen({Key? key}) : super(key: key);

  @override
  State<HandbookScreen> createState() => _HandbookScreenState();
}

class _HandbookScreenState extends State<HandbookScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  HandbookResponse? _handbookData;
  WeatherModel? _currentWeather;
  bool _isChatOpen = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHandbook();
    _messages.add(
      ChatMessage(
        text: 'Hello! I\'m your AI assistant. Ask me about flood safety, first aid, evacuation, or typhoon protocols.',
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

  Future<void> _loadHandbook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get current weather
      final weather = await ApiService.getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _currentWeather = weather;
      });

      // Generate handbook based on weather
      final handbook = await ApiService.generateHandbook(
        weatherDescription: weather.description,
        temperature: weather.temperature,
        precipitation: weather.precipitation,
        rain: weather.rain,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _handbookData = handbook;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading handbook: $e');
      // Try to load static tips as fallback
      try {
        final staticTips = await ApiService.getStaticTips();
        setState(() {
          _handbookData = HandbookResponse(
            weatherSummary: _currentWeather != null
                ? 'Current weather: ${_currentWeather!.description} at ${_currentWeather!.temperature.toStringAsFixed(1)}°C'
                : 'Weather data unavailable. Here are general safety tips.',
            safetyTips: staticTips,
            floodRiskLevel: 'moderate',
          );
          _errorMessage = 'Using offline safety tips';
          _isLoading = false;
        });
      } catch (fallbackError) {
        setState(() {
          _errorMessage = 'Failed to load safety tips: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.white60;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Icons.warning;
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.tips_and_updates;
      default:
        return Icons.check_circle;
    }
  }

  String _getRiskLevelDescription(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return 'Severe weather conditions detected';
      case 'moderate':
        return 'Moderate flood risk in your area';
      case 'low':
        return 'Weather conditions are currently favorable';
      default:
        return 'Unknown risk level';
    }
  }

  Color _getRiskLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.white60;
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isBot: false));
    });

    _messageController.clear();

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackgroundDeep
          : AppColors.lightBackgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Safety Handbook',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black87,
          ),
        ),
        backgroundColor: isDarkMode
            ? AppColors.darkBackgroundElevated
            : AppColors.lightBackgroundSecondary,
        foregroundColor: isDarkMode ? AppColors.darkTextPrimary : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadHandbook,
            tooltip: 'Refresh handbook',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null && _handbookData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadHandbook,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHandbook,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Weather Summary Card
                          if (_currentWeather != null)
                            Card(
                              elevation: 4,
                              color: isDarkMode
                                  ? AppColors.darkBackgroundElevated
                                  : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.wb_sunny,
                                          color: Colors.orange[700],
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Current Weather',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkMode
                                                      ? AppColors.darkTextPrimary
                                                      : Colors.black87,
                                                ),
                                              ),
                                              if (_handbookData?.weatherSummary !=
                                                  null)
                                                Text(
                                                  _handbookData!.weatherSummary,
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? AppColors.darkTextSecondary
                                                        : Colors.grey[700],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _WeatherDetail(
                                          icon: Icons.thermostat,
                                          label: 'Temp',
                                          value:
                                              '${_currentWeather!.temperature.toStringAsFixed(1)}°C',
                                          isDarkMode: isDarkMode,
                                        ),
                                        _WeatherDetail(
                                          icon: Icons.water_drop,
                                          label: 'Rain',
                                          value:
                                              '${_currentWeather!.precipitation.toStringAsFixed(1)}mm',
                                          isDarkMode: isDarkMode,
                                        ),
                                        _WeatherDetail(
                                          icon: Icons.air,
                                          label: 'Wind',
                                          value:
                                              '${_currentWeather!.windSpeed.toStringAsFixed(1)}km/h',
                                          isDarkMode: isDarkMode,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Flood Risk Level Badge
                          if (_handbookData?.floodRiskLevel != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getRiskLevelColor(
                                        _handbookData!.floodRiskLevel)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRiskLevelColor(
                                      _handbookData!.floodRiskLevel),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.shield,
                                    color: _getRiskLevelColor(
                                        _handbookData!.floodRiskLevel),
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_handbookData!.floodRiskLevel.toUpperCase()} RISK',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _getRiskLevelColor(
                                                _handbookData!.floodRiskLevel),
                                          ),
                                        ),
                                        Text(
                                          _getRiskLevelDescription(
                                              _handbookData!.floodRiskLevel),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode
                                                ? AppColors.darkTextSecondary
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Error message banner (if any)
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.orange),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(_errorMessage!)),
                                ],
                              ),
                            ),

                          // Safety Tips Header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Safety Tips',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (_handbookData?.weatherSummary != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome,
                                          size: 14, color: Colors.blue[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'AI',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _handbookData?.weatherSummary != null
                                ? 'AI-generated tips based on current weather conditions'
                                : 'General flood safety tips',
                            style: TextStyle(
                              color: isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Safety Tips List
                          if (_handbookData?.safetyTips != null)
                            ...(_handbookData!.safetyTips.asMap().entries.map(
                                (entry) {
                              final index = entry.key;
                              final tip = entry.value;
                              return _SafetyTipCard(
                                tip: tip,
                                number: index + 1,
                                priorityColor:
                                    _getPriorityColor(tip.priority),
                                priorityIcon:
                                    _getPriorityIcon(tip.priority),
                                isDarkMode: isDarkMode,
                              );
                            }))
                          else
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No safety tips available',
                                  style: GoogleFonts.montserrat(
                                    color: isDarkMode
                                        ? AppColors.darkTextSecondary
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 32),

                          // Footer
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkBackgroundElevated
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue[400], size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Pull down to refresh with latest weather conditions.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.blue[300],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
                      onTap: () {},
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 100, 16, 80),
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColors.darkBackgroundElevated.withOpacity(0.95)
                                : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDarkMode
                                  ? AppColors.darkBorder.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.1),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
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
                                    const Icon(
                                      Icons.smart_toy,
                                      color: Color(0xFFFF6B6B),
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
                                      icon: Icon(
                                        Icons.close,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: ListView.builder(
                                  controller: _chatScrollController,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    return ChatMessageWidget(
                                      message: _messages[index],
                                      isDarkMode: isDarkMode,
                                    );
                                  },
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
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
                                          color: isDarkMode
                                              ? AppColors.darkTextPrimary
                                              : Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Ask me anything...',
                                          hintStyle:
                                              GoogleFonts.montserrat(
                                            fontSize: 14,
                                            color: isDarkMode
                                                ? AppColors.darkTextSecondary
                                                : Colors.grey[500],
                                          ),
                                          filled: true,
                                          fillColor: isDarkMode
                                              ? AppColors.darkBackgroundDeep
                                              : Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder:
                                              OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder:
                                              OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
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
                                        backgroundColor: const Color(0xFFFF6B6B)
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

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDarkMode;

  const _WeatherDetail({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[400], size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey[700],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _SafetyTipCard extends StatelessWidget {
  final SafetyTip tip;
  final int number;
  final Color priorityColor;
  final IconData priorityIcon;
  final bool isDarkMode;

  const _SafetyTipCard({
    required this.tip,
    required this.number,
    required this.priorityColor,
    required this.priorityIcon,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDarkMode ? AppColors.darkBackgroundElevated : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: priorityColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: priorityColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: priorityColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                priorityIcon,
                                size: 12,
                                color: priorityColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tip.priority.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip.description,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
