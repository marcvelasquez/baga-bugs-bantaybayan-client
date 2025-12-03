import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../core/theme/colors.dart';
import '../core/theme/theme_provider.dart';
import '../widgets/flood_zone_painter.dart';

class SituationScreen extends StatefulWidget {
 const SituationScreen({super.key});

 @override
 State<SituationScreen> createState() => _SituationScreenState();
}

class _SituationScreenState extends State<SituationScreen> {
 // Pan and zoom state
 Offset _offset = Offset.zero;
 double _scale = 1.0;

 void _recenterMap() {
  setState(() {
   _offset = Offset.zero;
   _scale = 1.0;
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
   backgroundColor: isDarkMode ? AppColors.darkBackgroundDeep : AppColors.lightBackgroundPrimary,
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
         // Flood zone heatmaps
         Positioned.fill(
          child: CustomPaint(
           painter: FloodZonePainter(zones: floodZones),
          ),
         ),

         // Cluster markers at various positions
         ..._buildClusterMarkers(size, isDarkMode),
        ],
       ),
      ),
     ),

     // Fixed UI overlay
     SafeArea(
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        // Header
        Padding(
         padding: const EdgeInsets.all(16),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text(
            'Situation Reports',
            style: GoogleFonts.montserrat(
             fontSize: 20,
             fontWeight: FontWeight.w700,
             color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
           ),
           const SizedBox(height: 2),
           Text(
            'Crowd-sourced incident data',
            style: GoogleFonts.montserrat(
             fontSize: 13,
             color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
           ),
           const SizedBox(height: 12),
           // Active Reports card
           GestureDetector(
            onTap: () => _showActiveReportsModal(context),
            child: ClipRRect(
             borderRadius: BorderRadius.circular(16),
             child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
               decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.darkBackgroundElevated.withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                 color: Colors.black.withOpacity(0.1),
                ),
                boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                 ),
                ],
               ),
               child: IntrinsicHeight(
                child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
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
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                     ),
                    ),
                    const Spacer(),
                    Text(
                     _getCurrentDate(),
                     style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                     ),
                    ),
                   ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                   children: [
                    Expanded(
                     flex: 1,
                     child: _StatBox(
                      label: 'Info',
                      count: 5,
                      color: Colors.blue,
                     ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                     flex: 1,
                     child: _StatBox(
                      label: 'Critical',
                      count: 25,
                      color: const Color(0xFFFF6B6B),
                     ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                     flex: 1,
                     child: _StatBox(
                      label: 'Warning',
                      count: 8,
                      color: Colors.orange,
                     ),
                    ),
                   ],
                  ),
                 ],
                ),
               ),
              ),
             ),
            ),
           ),
          ],
         ),
        ),

        const Spacer(),
        // Report button at bottom
        Padding(
         padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
         child: _ReportButton(),
        ),
       ],
      ),
     ),

     // Recenter Button (bottom right, same level as report button)
     Positioned(
      right: 16,
      bottom: 20,
      child: FloatingActionButton(
       onPressed: _recenterMap,
       backgroundColor: Colors.white,
       mini: true,
       elevation: 4,
       child: const Icon(Icons.my_location, color: Colors.black87),
      ),
     ),
    ],
   ),
  );
 }

 List<Widget> _buildClusterMarkers(Size size, bool isDarkMode) {
  final markers = [
   (
    count: 10,
    severity: ClusterSeverity.high,
    position: const Offset(0.25, 0.3),
   ),
   (
    count: 5,
    severity: ClusterSeverity.medium,
    position: const Offset(0.65, 0.25),
   ),
   (
    count: 2,
    severity: ClusterSeverity.low,
    position: const Offset(0.45, 0.5),
   ),
   (
    count: 15,
    severity: ClusterSeverity.high,
    position: const Offset(0.75, 0.65),
   ),
   (
    count: 3,
    severity: ClusterSeverity.medium,
    position: const Offset(0.3, 0.75),
   ),
  ];

  return markers.map((marker) {
   return Positioned(
    left: size.width * marker.position.dx - 24,
    top: size.height * marker.position.dy - 24,
    child: _ClusterMarker(
     count: marker.count,
     severity: marker.severity,
     isDarkMode: isDarkMode,
    ),
   );
  }).toList();
 }

 void _showActiveReportsModal(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  showModalBottomSheet(
   context: context,
   isScrollControlled: true,
   backgroundColor: Colors.transparent,
   builder: (context) => Container(
    height: MediaQuery.of(context).size.height * 0.8,
    decoration: BoxDecoration(
     color: isDarkMode ? AppColors.darkBackgroundElevated : Colors.white,
     borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
     children: [
      // Header
      Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBackgroundDeep : Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
       ),
       child: Row(
        children: [
         Icon(
          Icons.assignment,
          color: AppColors.emergencyRed,
          size: 24,
         ),
         const SizedBox(width: 12),
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Text(
             'Active Reports',
             style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
             ),
            ),
            Text(
             'Real-time incident reports from the community',
             style: GoogleFonts.montserrat(
              fontSize: 12,
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
             ),
            ),
           ],
          ),
         ),
         IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
           Icons.close,
           color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
         ),
        ],
       ),
      ),
      
      // Reports List
      Expanded(
       child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeReports.length,
        itemBuilder: (context, index) {
         final report = _activeReports[index];
         return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
           color: isDarkMode ? AppColors.darkBackgroundDeep : Colors.grey[50],
           borderRadius: BorderRadius.circular(12),
           border: Border.all(
            color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorderPrimary,
           ),
          ),
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Row(
             children: [
              Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                color: _getReportColor(report['type']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
               ),
               child: Text(
                report['type'],
                style: GoogleFonts.montserrat(
                 fontSize: 10,
                 fontWeight: FontWeight.w600,
                 color: _getReportColor(report['type']),
                ),
               ),
              ),
              const Spacer(),
              Text(
               report['time'],
               style: GoogleFonts.montserrat(
                fontSize: 10,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
               ),
              ),
             ],
            ),
            const SizedBox(height: 8),
            Text(
             report['title'],
             style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
             ),
            ),
            const SizedBox(height: 4),
            Text(
             report['location'],
             style: GoogleFonts.montserrat(
              fontSize: 12,
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
             ),
            ),
           ],
          ),
         );
        },
       ),
      ),
     ],
    ),
   ),
  );
 }

 // Sample active reports data
 final List<Map<String, dynamic>> _activeReports = [
  {
   'type': 'Emergency',
   'title': 'Flood on Main Street',
   'location': 'Barangay San Antonio, Quezon City',
   'time': '2 min ago',
  },
  {
   'type': 'Alert',
   'title': 'Power Outage Reported',
   'location': 'Barangay Bago Bantay, Manila',
   'time': '5 min ago',
  },
  {
   'type': 'Info',
   'title': 'Road Closure Advisory',
   'location': 'EDSA-Quezon Avenue, Quezon City',
   'time': '8 min ago',
  },
  {
   'type': 'Emergency',
   'title': 'Fire Incident Report',
   'location': 'Barangay Tondo, Manila',
   'time': '12 min ago',
  },
  {
   'type': 'Alert',
   'title': 'Suspicious Activity',
   'location': 'Barangay Malate, Manila',
   'time': '15 min ago',
  },
 ];

 Color _getReportColor(String type) {
  switch (type) {
   case 'Emergency':
    return AppColors.emergencyRed;
   case 'Alert':
    return Colors.orange;
   case 'Info':
    return Colors.blue;
   default:
    return Colors.grey;
  }
 }
}

enum ClusterSeverity { high, medium, low }

class _ClusterMarker extends StatelessWidget {
 final int count;
 final ClusterSeverity severity;
 final bool isDarkMode;

 const _ClusterMarker({
  required this.count,
  required this.severity,
  required this.isDarkMode,
 });

 Color get _backgroundColor {
  switch (severity) {
   case ClusterSeverity.high:
    return const Color(0xFFFF6B6B); // Soft red matching map SOS button
   case ClusterSeverity.medium:
    return Colors.orange.withOpacity(0.7); // Lighter orange
   case ClusterSeverity.low:
    return Colors.blue.withOpacity(0.7); // Lighter blue
  }
 }

 Color get _glowColor {
  switch (severity) {
   case ClusterSeverity.high:
    return const Color(0xFFFF6B6B).withOpacity(0.3);
   case ClusterSeverity.medium:
    return Colors.orange.withOpacity(0.3);
   case ClusterSeverity.low:
    return Colors.blue.withOpacity(0.3);
  }
 }

 double get _glowRadius {
  switch (severity) {
   case ClusterSeverity.high:
    return 20.0;
   case ClusterSeverity.medium:
    return 15.0;
   case ClusterSeverity.low:
    return 10.0;
  }
 }

 @override
 Widget build(BuildContext context) {
  return Container(
   width: 48,
   height: 48,
   decoration: BoxDecoration(
    color: _backgroundColor,
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 3),
    boxShadow: [
     BoxShadow(
      color: _glowColor,
      blurRadius: _glowRadius,
      spreadRadius: 2,
     ),
    ],
   ),
   child: Center(
    child: Text(
     count.toString(),
     style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
     ),
    ),
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

class _ReportButton extends StatelessWidget {
 Future<void> _showReportModal(BuildContext context) async {
  await showDialog<String>(
   context: context,
   barrierDismissible: true,
   builder: (context) => const _ReportIncidentModal(),
  );
 }

 @override
 Widget build(BuildContext context) {
  return Container(
   decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
     BoxShadow(
      color: Colors.black.withOpacity(0.08),
      offset: const Offset(0, 2),
      blurRadius: 8,
     ),
    ],
   ),
   child: Material(
    color: Colors.black87,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
     onTap: () => _showReportModal(context),
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
 const _ReportIncidentModal();

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
   backgroundColor: Colors.white,
   shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
   ),
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
           color: Colors.black87.withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
           Icons.add_alert,
           color: Colors.black87,
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
              color: Colors.black87,
             ),
            ),
            Text(
             'Help keep your community safe',
             style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[600],
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
        color: Colors.black87,
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
               : Colors.grey[100],
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
               color: isSelected ? color : Colors.grey[600],
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
                color: isSelected ? color : Colors.grey[700],
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
        color: Colors.black87,
       ),
      ),
      const SizedBox(height: 8),
      TextField(
       controller: _descriptionController,
       maxLines: 3,
       style: GoogleFonts.montserrat(
        fontSize: 14,
        color: Colors.black87,
       ),
       decoration: InputDecoration(
        hintText: 'Describe what happened...',
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
          onPressed: _selectedType == null
            ? null
            : () {
              // Handle report submission
              Navigator.pop(context, _selectedType);
              ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                content: Text(
                 'Report submitted successfully',
                 style: GoogleFonts.montserrat(),
                ),
                backgroundColor: Colors.black87,
               ),
              );
             },
          style: ElevatedButton.styleFrom(
           backgroundColor: Colors.black87,
           padding: const EdgeInsets.symmetric(vertical: 12),
           shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
           ),
           disabledBackgroundColor: Colors.grey[300],
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
    ],
      ),
     ),
   ),
    );
   }
  }
