import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/colors.dart';
import '../core/theme/theme_provider.dart';
import '../widgets/sos_confirmation_modal.dart';
import '../widgets/profile_dropdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';

final Telephony telephony = Telephony.instance;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  bool _isSOSActive = false;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  // Default location (Manila, Philippines)
  static const LatLng _defaultLocation = LatLng(14.5995, 120.9842);
  LatLng _currentLocation = _defaultLocation;

  // Emergency locations (pinned)
  final List<EmergencyLocation> _emergencyLocations = [
    const EmergencyLocation(
      name: 'Evacuation Center A',
      position: LatLng(14.6020, 120.9880),
      type: EmergencyLocationType.evacuationCenter,
    ),
    const EmergencyLocation(
      name: 'Medical Station',
      position: LatLng(14.6050, 120.9900),
      type: EmergencyLocationType.medicalStation,
    ),
    const EmergencyLocation(
      name: 'Evacuation Center B',
      position: LatLng(14.5980, 120.9920),
      type: EmergencyLocationType.evacuationCenter,
    ),
    const EmergencyLocation(
      name: 'Relief Center',
      position: LatLng(14.6010, 120.9950),
      type: EmergencyLocationType.reliefCenter,
    ),
    const EmergencyLocation(
      name: 'General Hospital',
      position: LatLng(14.6040, 120.9820),
      type: EmergencyLocationType.hospital,
    ),
    const EmergencyLocation(
      name: 'Police Station 1',
      position: LatLng(14.5970, 120.9860),
      type: EmergencyLocationType.policeStation,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _createMarkers();
    _createFloodZones();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_latitude', position.latitude);
      await prefs.setDouble('user_longitude', position.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation));
    } catch (e) {
      // Use default location if getting current location fails
    }
  }

  void _sendSOS(String phone, String message) async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted ?? false) {
      try {
        await telephony.sendSms(to: phone, message: message);
        print('SOS SMS sent to $phone!');
      } catch (e) {
        print('Failed to send SMS: $e');
      }
    } else {
      print('SMS permission denied');
    }
  }

  void _createMarkers() {
    for (var location in _emergencyLocations) {
      _markers.add(
        Marker(
          markerId: MarkerId(location.name),
          position: location.position,
          infoWindow: InfoWindow(
            title: location.name,
            snippet: location.type.toString().split('.').last,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(location.type),
          ),
        ),
      );
    }
  }

  double _getMarkerHue(EmergencyLocationType type) {
    switch (type) {
      case EmergencyLocationType.evacuationCenter:
        return BitmapDescriptor.hueOrange;
      case EmergencyLocationType.medicalStation:
      case EmergencyLocationType.hospital:
        return BitmapDescriptor.hueAzure;
      case EmergencyLocationType.policeStation:
        return BitmapDescriptor.hueViolet;
      case EmergencyLocationType.reliefCenter:
        return BitmapDescriptor.hueGreen;
    }
  }

  void _createFloodZones() {
    // Define flood zones as circles
    final floodZones = [
      const LatLng(14.6000, 120.9870),
      const LatLng(14.6030, 120.9900),
      const LatLng(14.5990, 120.9930),
    ];

    for (int i = 0; i < floodZones.length; i++) {
      _circles.add(
        Circle(
          circleId: CircleId('flood_zone_$i'),
          center: floodZones[i],
          radius: 300, // 300 meters
          fillColor: AppColors.floodZoneRed.withOpacity(0.3),
          strokeColor: AppColors.floodZoneRed.withOpacity(0.6),
          strokeWidth: 2,
        ),
      );
    }
  }

  void _recenterMap() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 14),
      );
    }
  }

  void _onSOSConfirmed() async {
    setState(() {
      _isSOSActive = true;
    });

    // Use _currentLocation directly
    final lat = _currentLocation.latitude;
    final lng = _currentLocation.longitude;

    // Optionally get phone number from SharedPreferences
    String phone = "09925377030";
    String message = 'ENAV|SOS|$lat|$lng|$phone|flood|.5';
    _sendSOS(phone, message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackgroundDeep
          : AppColors.lightBackgroundPrimary,
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultLocation,
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (isDarkMode) {
                controller.setMapStyle('''
                  [
                    {
                      "elementType": "geometry",
                      "stylers": [{"color": "#242f3e"}]
                    },
                    {
                      "elementType": "labels.text.fill",
                      "stylers": [{"color": "#746855"}]
                    },
                    {
                      "elementType": "labels.text.stroke",
                      "stylers": [{"color": "#242f3e"}]
                    },
                    {
                      "featureType": "water",
                      "elementType": "geometry",
                      "stylers": [{"color": "#17263c"}]
                    }
                  ]
                ''');
              }
            },
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
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
                          '${_currentLocation.latitude.toStringAsFixed(4)}° N',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${_currentLocation.longitude.toStringAsFixed(4)}° E',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Profile dropdown
                    const ProfileDropdown(),
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
  final LatLng position;
  final EmergencyLocationType type;

  const EmergencyLocation({
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
