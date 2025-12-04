import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../core/theme/colors.dart';
import '../core/theme/theme_provider.dart';

class SituationScreen extends StatefulWidget {
  const SituationScreen({super.key});

  @override
  State<SituationScreen> createState() => _SituationScreenState();
}

class _SituationScreenState extends State<SituationScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  LatLng? _userPinLocation;
  ReportStats? _reportStats;
  bool _isLoadingStats = false;
  List<ReportModel> _allReports = [];
  WeatherModel? _currentWeather;

  // Default location (Manila, Philippines)
  static const LatLng _defaultLocation = LatLng(14.5995, 120.9842);
  LatLng _currentLocation = _defaultLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getCurrentLocation();
    _loadReportStats();
    _loadReports();
    _loadWeather();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reapply map style when app comes to foreground
      _applyMapStyle();
    }
  }

  void _applyMapStyle() {
    if (_mapController != null) {
      _mapController!.setMapStyle('''
        [
          {
            "elementType": "geometry",
            "stylers": [{"color": "#1a1621"}]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#ffffff"}]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#1a1621"}]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [{"color": "#2a2234"}]
          },
          {
            "featureType": "road",
            "elementType": "geometry",
            "stylers": [{"color": "#3a3047"}]
          },
          {
            "featureType": "road",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#ffffff"}]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry",
            "stylers": [{"color": "#4a4057"}]
          },
          {
            "featureType": "poi",
            "elementType": "geometry",
            "stylers": [{"color": "#2a2234"}]
          },
          {
            "featureType": "poi",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#ffffff"}]
          },
          {
            "featureType": "administrative",
            "elementType": "geometry.stroke",
            "stylers": [{"color": "#3a3047"}]
          },
          {
            "featureType": "administrative",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#ffffff"}]
          }
        ]
      ''');
    }
  }

  Future<void> _loadWeather() async {
    try {
      final weather = await ApiService.getCurrentWeather(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
      );
      setState(() {
        _currentWeather = weather;
      });
    } catch (e) {
      debugPrint('❌ Failed to load weather: $e');
    }
  }

  Future<void> _loadReports() async {
    try {
      debugPrint('🔄 Loading reports from API...');
      final reports = await ApiService.getReports();
      debugPrint('✅ Loaded ${reports.length} reports');
      setState(() {
        _allReports = reports;
      });
      _updateReportMarkers();
    } catch (e) {
      // Show error in UI for debugging
      debugPrint('❌ Failed to load reports: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _updateReportMarkers() {
    debugPrint('🗺️ Updating report markers for ${_allReports.length} reports');

    // Clear existing report markers/circles but keep user pin
    _markers.removeWhere((marker) => marker.markerId.value != 'user_pin');
    _circles.clear();

    // Cluster reports by proximity
    final clusters = _clusterReports(_allReports);

    debugPrint('📍 Created ${clusters.length} clusters');

    // Create markers and circles for each cluster
    for (var cluster in clusters) {
      final opacity = _calculateOpacity(cluster.reports.length);
      final color = _getColorForType(cluster.incidentType);

      debugPrint(
        '  Cluster at ${cluster.center.latitude}, ${cluster.center.longitude}: ${cluster.reports.length} reports, opacity: $opacity',
      );

      // Add circle for affected area
      _circles.add(
        Circle(
          circleId: CircleId(
            'cluster_${cluster.center.latitude}_${cluster.center.longitude}',
          ),
          center: cluster.center,
          radius:
              100 +
              (cluster.reports.length * 50.0), // Larger radius for more reports
          fillColor: color.withOpacity(opacity * 0.3),
          strokeColor: color.withOpacity(opacity),
          strokeWidth: 2,
        ),
      );

      // Add marker
      _markers.add(
        Marker(
          markerId: MarkerId(
            'cluster_${cluster.center.latitude}_${cluster.center.longitude}',
          ),
          position: cluster.center,
          alpha: opacity,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(cluster.incidentType),
          ),
          infoWindow: InfoWindow(
            title: '${cluster.incidentType.name.toUpperCase()} Reports',
            snippet:
                '${cluster.reports.length} report${cluster.reports.length > 1 ? 's' : ''}',
          ),
        ),
      );
    }

    debugPrint(
      '✅ Added ${_markers.length} markers and ${_circles.length} circles to map',
    );

    setState(() {});
  }

  List<ReportCluster> _clusterReports(List<ReportModel> reports) {
    if (reports.isEmpty) return [];

    final clusters = <ReportCluster>[];
    final processed = <int>{};

    for (var i = 0; i < reports.length; i++) {
      if (processed.contains(i)) continue;

      final centerReport = reports[i];
      final clusterReports = <ReportModel>[centerReport];
      processed.add(i);

      // Find nearby reports of the same type
      for (var j = i + 1; j < reports.length; j++) {
        if (processed.contains(j)) continue;

        final report = reports[j];
        final distance = _calculateDistance(
          centerReport.latitude,
          centerReport.longitude,
          report.latitude,
          report.longitude,
        );

        // Cluster if within 500 meters and same type
        if (distance < 500 &&
            report.incidentType == centerReport.incidentType) {
          clusterReports.add(report);
          processed.add(j);
        }
      }

      // Calculate cluster center
      final avgLat =
          clusterReports.map((r) => r.latitude).reduce((a, b) => a + b) /
          clusterReports.length;
      final avgLng =
          clusterReports.map((r) => r.longitude).reduce((a, b) => a + b) /
          clusterReports.length;

      clusters.add(
        ReportCluster(
          center: LatLng(avgLat, avgLng),
          reports: clusterReports,
          incidentType: centerReport.incidentType,
        ),
      );
    }

    return clusters;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(a)); // 2 * R * asin... (in meters)
  }

  double _calculateOpacity(int reportCount) {
    // Map report count to opacity: 1 report = 0.3, 5+ reports = 1.0
    return (0.3 + (reportCount - 1) * 0.175).clamp(0.3, 1.0);
  }

  Color _getColorForType(IncidentType type) {
    switch (type) {
      case IncidentType.critical:
        return const Color(0xFFFF6B6B);
      case IncidentType.warning:
        return Colors.orange;
      case IncidentType.info:
        return Colors.blue;
    }
  }

  double _getMarkerHue(IncidentType type) {
    switch (type) {
      case IncidentType.critical:
        return BitmapDescriptor.hueRed;
      case IncidentType.warning:
        return BitmapDescriptor.hueOrange;
      case IncidentType.info:
        return BitmapDescriptor.hueAzure;
    }
  }

  Future<void> _loadReportStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await ApiService.getReportStats();
      setState(() {
        _reportStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      // Show error but continue with default values
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation));
    } catch (e) {
      // Use default location if getting current location fails
    }
  }

  void _recenterMap() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 14),
      );
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      // Remove previous pin if exists
      _markers.removeWhere((marker) => marker.markerId.value == 'user_pin');

      // Add new pin
      _userPinLocation = position;
      _markers.add(
        Marker(
          markerId: const MarkerId('user_pin'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Report Location'),
        ),
      );
    });
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  IconData _getWeatherIcon(int weatherCode) {
    if (weatherCode == 0 || weatherCode == 1) {
      return Icons.wb_sunny;
    } else if (weatherCode == 2 || weatherCode == 3) {
      return Icons.wb_cloudy;
    } else if (weatherCode >= 51 && weatherCode <= 67) {
      return Icons.grain;
    } else if (weatherCode >= 61 && weatherCode <= 82) {
      return Icons.water_drop;
    } else if (weatherCode >= 95) {
      return Icons.flash_on;
    } else {
      return Icons.cloud;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Apply dark mode styling
              _applyMapStyle();
            },
            markers: _markers,
            circles: _circles,
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Fixed UI overlay
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Merged Header + Active Reports
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkBackgroundElevated.withOpacity(0.95)
                        : AppColors.lightBackgroundSecondary.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? AppColors.darkBorder
                          : AppColors.lightBorderPrimary,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Situation Report',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFFFF6B6B).withOpacity(0.15)
                                  : Colors.blue[700]!.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                _loadReportStats();
                                _loadReports();
                              },
                              icon: Icon(
                                Icons.refresh,
                                color: isDarkMode
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.blue[700],
                                size: 20,
                              ),
                              tooltip: 'Refresh reports',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Active Reports stats row
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Active Reports',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoadingStats)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDarkMode
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                _loadReportStats();
                                _loadReports();
                              },
                              child: Icon(
                                Icons.refresh,
                                size: 14,
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black.withOpacity(0.6),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            _reportStats?.date ?? _getCurrentDate(),
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stats boxes (compact)
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _StatBox(
                              label: 'Info',
                              count: _reportStats?.infoCount ?? 0,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _StatBox(
                              label: 'Warning',
                              count: _reportStats?.warningCount ?? 0,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _StatBox(
                              label: 'Critical',
                              count: _reportStats?.criticalCount ?? 0,
                              color: const Color(0xFFFF6B6B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Report button at bottom (only show if pin is placed)
                if (_userPinLocation != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: _ReportButton(location: _userPinLocation!),
                  ),
              ],
            ),
          ),

          // Recenter Button (bottom right)
          Positioned(
            right: 16,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: _recenterMap,
              backgroundColor: const Color(0xFF3a3047),
              mini: true,
              elevation: 4,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBox({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReportButton extends StatefulWidget {
  final LatLng location;

  const _ReportButton({required this.location});

  @override
  State<_ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<_ReportButton> {
  List<ReportModel> _nearbyReports = [];
  bool _isCheckingNearby = false;

  @override
  void initState() {
    super.initState();
    _checkNearbyReports();
  }

  @override
  void didUpdateWidget(_ReportButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check when location changes
    if (oldWidget.location != widget.location) {
      debugPrint('🔄 Pin location changed, re-checking nearby reports...');
      _checkNearbyReports();
    }
  }

  Future<void> _checkNearbyReports() async {
    debugPrint(
      '🔍 Checking for nearby reports at (${widget.location.latitude}, ${widget.location.longitude})',
    );
    setState(() => _isCheckingNearby = true);
    try {
      final nearby = await ApiService.getNearbyReports(
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        radius: 500.0, // 500 meters for easier testing
      );
      debugPrint('✅ Found ${nearby.length} nearby reports');
      setState(() {
        _nearbyReports = nearby;
        _isCheckingNearby = false;
      });
    } catch (e) {
      debugPrint('❌ Error checking nearby reports: $e');
      setState(() => _isCheckingNearby = false);
    }
  }

  Future<void> _showReportModal() async {
    await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ReportIncidentModal(location: widget.location),
    );
  }

  Future<void> _showNearbyReportsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _NearbyReportsDialog(
        location: widget.location,
        nearbyReports: _nearbyReports,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingNearby) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF3a3047),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Checking area...',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // If there are nearby reports, show upvote option
    if (_nearbyReports.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.08),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Material(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _showNearbyReportsDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.thumb_up, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '${_nearbyReports.length} Report${_nearbyReports.length > 1 ? 's' : ''} Nearby - Upvote?',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // No nearby reports, show normal report button
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFF3a3047),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _showReportModal,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_alert, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Report Incident',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _ReportIncidentModal extends StatefulWidget {
  final LatLng location;

  const _ReportIncidentModal({required this.location});

  @override
  State<_ReportIncidentModal> createState() => _ReportIncidentModalState();
}

class _ReportIncidentModalState extends State<_ReportIncidentModal> {
  String? _selectedType;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Critical':
        return const Color(0xFFFF6B6B);
      case 'Warning':
        return Colors.orange;
      case 'Info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2a2234),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_alert,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Incident',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Help keep your community safe',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Incident Type',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: ['Info', 'Critical', 'Warning'].map((type) {
                  final isSelected = _selectedType == type;
                  final color = _getTypeColor(type);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedType = type),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.15)
                                : const Color(0xFF3a3047),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                type == 'Critical'
                                    ? Icons.error
                                    : type == 'Warning'
                                    ? Icons.warning_amber_rounded
                                    : Icons.info,
                                color: isSelected ? color : Colors.white60,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected ? color : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Description (Optional)',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe what happened...',
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF3a3047),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.white54),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedType == null
                          ? null
                          : () async {
                              // Handle report submission
                              Navigator.pop(context);

                              // Show loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Submitting report...',
                                        style: GoogleFonts.montserrat(),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.black87,
                                  duration: const Duration(seconds: 2),
                                ),
                              );

                              try {
                                // Convert type to IncidentType enum
                                IncidentType incidentType;
                                switch (_selectedType) {
                                  case 'Critical':
                                    incidentType = IncidentType.critical;
                                    break;
                                  case 'Warning':
                                    incidentType = IncidentType.warning;
                                    break;
                                  case 'Info':
                                  default:
                                    incidentType = IncidentType.info;
                                }

                                // Create report
                                final report = ReportModel(
                                  incidentType: incidentType,
                                  latitude: widget.location.latitude,
                                  longitude: widget.location.longitude,
                                  description:
                                      _descriptionController.text.isEmpty
                                      ? null
                                      : _descriptionController.text,
                                );

                                await ApiService.createReport(report);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Report submitted successfully',
                                      style: GoogleFonts.montserrat(),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // Reload stats and reports after successful submission
                                if (context.mounted) {
                                  final situationScreenState = context
                                      .findAncestorStateOfType<
                                        _SituationScreenState
                                      >();
                                  situationScreenState?._loadReportStats();
                                  situationScreenState?._loadReports();
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to submit report: $e',
                                      style: GoogleFonts.montserrat(),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3a3047),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: const Color(0xFF2a2234),
                      ),
                      child: Text(
                        'Submit',
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
              const SizedBox(height: 16),
              // Location info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3a3047),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lat: ${widget.location.latitude.toStringAsFixed(6)}, Lng: ${widget.location.longitude.toStringAsFixed(6)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
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

// Nearby reports dialog widget
class _NearbyReportsDialog extends StatefulWidget {
  final LatLng location;
  final List<ReportModel> nearbyReports;

  const _NearbyReportsDialog({
    required this.location,
    required this.nearbyReports,
  });

  @override
  State<_NearbyReportsDialog> createState() => _NearbyReportsDialogState();
}

class _NearbyReportsDialogState extends State<_NearbyReportsDialog> {
  final Set<int> _upvotedReports = {};
  final Map<int, int> _reportUpvoteCounts = {};

  @override
  void initState() {
    super.initState();
    // Initialize upvote counts
    for (var report in widget.nearbyReports) {
      _reportUpvoteCounts[report.id!] = report.upvoteCount;
    }
  }

  Future<void> _handleUpvote(ReportModel report) async {
    final reportId = report.id!;

    try {
      await ApiService.upvoteReport(reportId);
      setState(() {
        _upvotedReports.add(reportId);
        _reportUpvoteCounts[reportId] =
            (_reportUpvoteCounts[reportId] ?? 0) + 1;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upvoted report successfully!',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('already upvoted')
                  ? 'You already upvoted this report'
                  : 'Failed to upvote: ${e.toString()}',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _createNewReport() async {
    Navigator.pop(context);
    await showDialog(
      context: context,
      builder: (context) => _ReportIncidentModal(location: widget.location),
    );
  }

  Color _getIncidentColor(IncidentType type) {
    switch (type) {
      case IncidentType.critical:
        return const Color(0xFFFF6B6B);
      case IncidentType.warning:
        return Colors.orange;
      case IncidentType.info:
        return Colors.blue;
    }
  }

  IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.critical:
        return Icons.error;
      case IncidentType.warning:
        return Icons.warning_amber_rounded;
      case IncidentType.info:
        return Icons.info;
    }
  }

  String _getIncidentLabel(IncidentType type) {
    switch (type) {
      case IncidentType.critical:
        return 'Critical';
      case IncidentType.warning:
        return 'Warning';
      case IncidentType.info:
        return 'Info';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2a2234),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Reports',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${widget.nearbyReports.length} report${widget.nearbyReports.length > 1 ? 's' : ''} within 100m',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.nearbyReports.length,
                itemBuilder: (context, index) {
                  final report = widget.nearbyReports[index];
                  final reportId = report.id!;
                  final isUpvoted = _upvotedReports.contains(reportId);
                  final upvoteCount =
                      _reportUpvoteCounts[reportId] ?? report.upvoteCount;
                  final color = _getIncidentColor(report.incidentType);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            _getIncidentIcon(report.incidentType),
                            color: color,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getIncidentLabel(report.incidentType),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (report.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    report.description!,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              IconButton(
                                onPressed: isUpvoted
                                    ? null
                                    : () => _handleUpvote(report),
                                icon: Icon(
                                  isUpvoted
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_outlined,
                                  color: isUpvoted ? color : Colors.white60,
                                  size: 20,
                                ),
                                tooltip: isUpvoted
                                    ? 'Already upvoted'
                                    : 'Upvote',
                              ),
                              Text(
                                '$upvoteCount',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.white54),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createNewReport,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF3a3047),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create New',
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
    );
  }
}

// Helper class for clustering reports
class ReportCluster {
  final LatLng center;
  final List<ReportModel> reports;
  final IncidentType incidentType;

  ReportCluster({
    required this.center,
    required this.reports,
    required this.incidentType,
  });
}
