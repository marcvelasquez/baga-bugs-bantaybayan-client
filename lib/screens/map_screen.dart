import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/colors.dart';
import '../core/theme/theme_provider.dart';
import '../widgets/flood_zone_painter.dart';
import '../widgets/sos_confirmation_modal.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Pan and zoom state
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  bool _isSOSActive = false;

  // Emergency locations (pinned)
  final List<EmergencyLocation> _emergencyLocations = [
    EmergencyLocation(
      name: 'Evacuation Center A',
      position: const Offset(0.2, 0.3),
      type: EmergencyLocationType.evacuationCenter,
    ),
    EmergencyLocation(
      name: 'Medical Station',
      position: const Offset(0.6, 0.4),
      type: EmergencyLocationType.medicalStation,
    ),
    EmergencyLocation(
      name: 'Evacuation Center B',
      position: const Offset(0.4, 0.6),
      type: EmergencyLocationType.evacuationCenter,
    ),
    EmergencyLocation(
      name: 'Relief Center',
      position: const Offset(0.7, 0.7),
      type: EmergencyLocationType.reliefCenter,
    ),
    EmergencyLocation(
      name: 'General Hospital',
      position: const Offset(0.5, 0.2),
      type: EmergencyLocationType.hospital,
    ),
    EmergencyLocation(
      name: 'Police Station 1',
      position: const Offset(0.3, 0.8),
      type: EmergencyLocationType.policeStation,
    ),
  ];

  void _recenterMap() {
    setState(() {
      _offset = Offset.zero;
      _scale = 1.0;
    });
  }

  void _onSOSConfirmed() {
    setState(() {
      _isSOSActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;

    // Define flood zones
    final floodZones = [
      const FloodZone(center: Offset(0.3, 0.4), radius: 120, opacity: 0.6),
      const FloodZone(center: Offset(0.7, 0.3), radius: 90, opacity: 0.4),
      const FloodZone(center: Offset(0.5, 0.7), radius: 100, opacity: 0.5),
    ];

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackgroundDeep
          : AppColors.lightBackgroundPrimary,
      body: Stack(
        children: [
          // Pannable and zoomable map
          GestureDetector(
            onScaleStart: (details) {
              setState(() {
                // Store initial values
              });
            },
            onScaleUpdate: (details) {
              setState(() {
                _scale = (_scale * details.scale).clamp(0.5, 3.0);
                _offset += details.focalPointDelta;
              });
            },
            child: Transform(
              transform: Matrix4.identity()
                ..translate(_offset.dx, _offset.dy)
                ..scale(_scale),
              child: Stack(
                children: [
                  // Map background (Clean, no grid)
                  Positioned.fill(
                    child: Container(
                      color: isDarkMode
                          ? AppColors.darkBackgroundDeep
                          : AppColors.lightBackgroundPrimary,
                    ),
                  ),

                  // Flood zone heatmaps
                  Positioned.fill(
                    child: CustomPaint(
                      painter: FloodZonePainter(zones: floodZones),
                    ),
                  ),

                  // Emergency location pins
                  ..._emergencyLocations.map((location) {
                    return Positioned(
                      left: size.width * location.position.dx - 20,
                      top: size.height * location.position.dy - 20,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          location.icon,
                          color: location.color.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),

                  // Location marker (centered)
                  Positioned(
                    left: size.width / 2 - 20,
                    top: size.height / 2 - 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSOSActive
                            ? AppColors.emergencyRed
                            : Colors.blueAccent,
                        border: Border.all(
                          color: AppColors.locationMarkerBorder,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isSOSActive
                                        ? AppColors.emergencyRed
                                        : Colors.blueAccent)
                                    .withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Offline indicator (icon only)
                    Icon(
                      Icons.wifi_off,
                      size: 20,
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.5),
                    ),
                    const SizedBox(width: 12),
                    // GPS coordinates (stacked)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '14.5995° N',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '120.9842° E',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Theme toggle button
                    IconButton(
                      onPressed: () => themeProvider.toggleTheme(),
                      icon: Icon(
                        isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search bar (full width, lower position)
          Positioned(
            left: 0,
            right: 0,
            top: 120,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => _SearchDialog(
                      locations: _emergencyLocations,
                      isDarkMode: isDarkMode,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600], size: 22),
                    const SizedBox(width: 14),
                    Text(
                      'Search emergency locations...',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legend box (bottom left, above SOS)
          Positioned(
            left: 16,
            bottom: 110,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(
                    color: AppColors.floodZoneRed,
                    label: 'Flood',
                    theme: theme,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    color: _isSOSActive
                        ? const Color(0xFFFF6B6B)
                        : Colors.blueAccent,
                    label: 'You',
                    theme: theme,
                    isDarkMode: isDarkMode,
                    isBordered: true,
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    color: Colors.blue,
                    label: 'Hospital',
                    theme: theme,
                    isDarkMode: isDarkMode,
                    icon: Icons.local_hospital,
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    color: Colors.orange,
                    label: 'Shelter',
                    theme: theme,
                    isDarkMode: isDarkMode,
                    icon: Icons.family_restroom,
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    color: Colors.indigo,
                    label: 'Police',
                    theme: theme,
                    isDarkMode: isDarkMode,
                    icon: Icons.local_police,
                  ),
                ],
              ),
            ),
          ),

          // Recenter Button (bottom right, above SOS)
          Positioned(
            right: 16,
            bottom: 110,
            child: FloatingActionButton(
              onPressed: _recenterMap,
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
              mini: true,
              child: Icon(
                Icons.my_location,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),

          // SOS Button (minimal, clean design)
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: _SOSButton(
              isDarkMode: isDarkMode,
              onSOSConfirmed: _onSOSConfirmed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required ThemeData theme,
    required bool isDarkMode,
    bool isBordered = false,
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Icon(icon, size: 10, color: color.withOpacity(0.7)),
          )
        else
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isBordered
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDarkMode
                ? Colors.white.withOpacity(0.8)
                : Colors.black.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

enum EmergencyLocationType {
  evacuationCenter,
  medicalStation,
  policeStation,
  reliefCenter,
  hospital,
}

// Emergency location model
class EmergencyLocation {
  final String name;
  final Offset position;
  final EmergencyLocationType type;

  EmergencyLocation({
    required this.name,
    required this.position,
    required this.type,
  });

  Color get color {
    switch (type) {
      case EmergencyLocationType.evacuationCenter:
        return Colors.orange;
      case EmergencyLocationType.medicalStation:
      case EmergencyLocationType.hospital:
        return Colors.blue;
      case EmergencyLocationType.policeStation:
        return Colors.indigo;
      case EmergencyLocationType.reliefCenter:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (type) {
      case EmergencyLocationType.evacuationCenter:
        return Icons.family_restroom;
      case EmergencyLocationType.medicalStation:
      case EmergencyLocationType.hospital:
        return Icons.local_hospital;
      case EmergencyLocationType.policeStation:
        return Icons.local_police;
      case EmergencyLocationType.reliefCenter:
        return Icons.volunteer_activism;
    }
  }
}

// Search dialog
class _SearchDialog extends StatefulWidget {
  final List<EmergencyLocation> locations;
  final bool isDarkMode;

  const _SearchDialog({required this.locations, required this.isDarkMode});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  List<EmergencyLocation> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = widget.locations;
      } else {
        _results = widget.locations
            .where(
              (loc) => loc.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search emergency locations...',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final location = _results[index];
                  return ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: Icon(
                        location.icon,
                        size: 16,
                        color: location.color.withOpacity(0.7),
                      ),
                    ),
                    title: Text(
                      location.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Could add navigation to location here
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SOS Button with pulsing animation (narrower height)
class _SOSButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onSOSConfirmed;

  const _SOSButton({required this.isDarkMode, required this.onSOSConfirmed});

  Future<void> _showSOSModal(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SOSConfirmationModal(),
    );

    if (result == true) {
      onSOSConfirmed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.25),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFFF6B6B),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showSOSModal(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SOS',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withOpacity(0.4),
                ),
                const SizedBox(width: 12),
                Text(
                  'Emergency Assistance',
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
