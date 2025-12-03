import 'package:flutter/material.dart';

/// BantayBayan Color Palette
/// Tactical Minimalist Design - Dark/Light Mode Support with OKLCH Colors
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ===== DARK MODE COLORS (OKLCH Based) =====

  // Dark Mode Backgrounds - OKLCH color scheme
  static const Color darkBackgroundDeep = Color(0xFF1A1A24); // oklch(12.9% 0.042 264.695) converted to hex
  static const Color darkBackgroundMid = Color(0xFF222230); // Slightly lighter variation
  static const Color darkBackgroundElevated = Color(0xFF3E3E4E); // oklch(27.9% 0.041 260.031) converted to hex

  // Dark Mode Text
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // White
  static const Color darkTextSecondary = Color(0x99FFFFFF); // White 60% opacity
  static const Color darkTextTertiary = Color(0x66FFFFFF); // White 40% opacity

  // Dark Mode Borders (for glass effect)
  static const Color darkBorder = Color(0x33FFFFFF); // White 20% opacity

  // ===== LIGHT MODE COLORS (Black & White) =====

  // Light Mode Backgrounds
  static const Color lightBackgroundPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color lightBackgroundSecondary = Color(0xFFF5F5F5); // Off-White
  static const Color lightBackgroundTertiary = Color(0x33000000); // Black 20% opacity (glass)

  // Light Mode Text
  static const Color lightTextPrimary = Color(0xFF000000); // Pure Black
  static const Color lightTextSecondary = Color(0x99000000); // Black 60% opacity
  static const Color lightTextTertiary = Color(0x66000000); // Black 40% opacity

  // Light Mode Borders (for glass effect)
  static const Color lightBorderPrimary = Color(0x33000000); // Black 20% opacity
  static const Color lightBorderSecondary = Color(0x1A000000); // Black 10% opacity

  // ===== SHARED COLORS =====

  // Emergency Red - SOS elements, critical alerts (keeping the pink theme)
  static const Color emergencyRed = Color(0xFFFF6B6B); // #FF6B6B (pink theme)
  static const Color emergencyRedDark = Color(0xFFE55555);
  static const Color emergencyRedLight = Color(0xFFFF8A8A);

  // High-Vis Amber - Alerts and accents
  static const Color amberDark = Color(0xFFFFCC00); // #FFCC00 for dark mode
  static const Color amberLight = Color(0xFFCC9900); // #CC9900 for light mode
  static const Color amberAccent = Color(0xFFFFDD44);

  // Status Colors
  static const Color statusCritical = Color(0xFFFF6B6B); // Pink
  static const Color statusWarning = Color(0xFFFFCC00); // Amber
  static const Color statusInfo = Color(0xFF64748B); // Gray
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Map Overlay Colors
  static const Color floodZoneRed = Color(0x66FF6B6B); // Semi-transparent pink
  static const Color locationMarker = Color(0xFFFF6B6B); // Pink marker
  static const Color locationMarkerBorder = Color(0xFFFFFFFF); // White border

  // Cluster Marker Severity Levels
  static const Color clusterHigh = Color(0xFFFF6B6B); // Pink
  static const Color clusterMedium = Color(0xFFFFCC00); // Amber
  static const Color clusterLow = Color(0xFF64748B); // Gray

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000); // 10% black
  static const Color shadowMedium = Color(0x33000000); // 20% black
  static const Color shadowHeavy = Color(0x66000000); // 40% black

  // Glow Effects
  static const Color glowRed = Color(0x66FF6B6B); // Pink glow
  static const Color glowAmber = Color(0x66FFCC00); // Amber glow
  static const Color glowGray = Color(0x33000000); // Gray glow

  // ===== LEGACY ALIASES (for backward compatibility) =====
  // These map old color names to the new OKLCH theme
  static const Color backgroundDeep = Color(0xFF1A1A24); // Maps to OKLCH main color
  static const Color backgroundElevated = Color(0xFF3E3E4E); // Maps to OKLCH secondary
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Pure white
  static const Color textOnLight = Color(0xFF000000); // Black text
  static const Color textSecondary = Color(0x99FFFFFF); // White 60% opacity
  static const Color slateGrey = Color(0xFF64748B); // Gray
  static const Color alertAmber = Color(0xFFFFCC00); // Amber
}
