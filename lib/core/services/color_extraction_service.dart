import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Wrapper class for color compatibility
class ColorWrapper {
  final Color color;
  ColorWrapper(this.color);
}

/// Color extraction service to replace discontinued palette_generator
/// Provides dominant color extraction from images
class ColorExtractionService {
  static final ColorExtractionService _instance = ColorExtractionService._internal();
  factory ColorExtractionService() => _instance;
  ColorExtractionService._internal();

  // Cached colors for compatibility
  Color? _lightVibrantColor;
  Color? _darkMutedColor;
  Color? _dominantColor;

  // Compatibility properties
  ColorWrapper? get lightVibrantColor => _lightVibrantColor != null 
      ? ColorWrapper(_lightVibrantColor!) : null;
  ColorWrapper? get darkMutedColor => _darkMutedColor != null 
      ? ColorWrapper(_darkMutedColor!) : null;
  ColorWrapper? get dominantColor => _dominantColor != null 
      ? ColorWrapper(_dominantColor!) : null;

  /// Extract dominant color from image bytes
  Future<Color> extractDominantColor(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) return Colors.deepPurple;

      // Resize image for faster processing
      final resized = img.copyResize(image, width: 50, height: 50);
      
      // Extract colors and find dominant
      final colorCounts = <int, int>{};
      
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          final color = _pixelToColor(pixel);
          
          // Skip very dark or very light colors
          if (_isValidColor(color)) {
            final colorKey = color.value;
            colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
          }
        }
      }

      if (colorCounts.isEmpty) return Colors.deepPurple;

      // Find most frequent color
      final dominantColorValue = colorCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final dominantColor = Color(dominantColorValue);
      
      // Cache colors for compatibility
      _dominantColor = dominantColor;
      _lightVibrantColor = dominantColor;
      _darkMutedColor = dominantColor.withOpacity(0.7);

      return dominantColor;
    } catch (e) {
      print('Error extracting color: $e');
      final fallbackColor = Colors.deepPurple;
      _dominantColor = fallbackColor;
      _lightVibrantColor = fallbackColor;
      _darkMutedColor = fallbackColor.withOpacity(0.7);
      return fallbackColor;
    }
  }

  /// Extract color palette from image
  Future<List<Color>> extractColorPalette(Uint8List imageBytes, {int maxColors = 5}) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return [Colors.deepPurple];

      final resized = img.copyResize(image, width: 100, height: 100);
      final colorCounts = <int, int>{};
      
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          final color = _pixelToColor(pixel);
          
          if (_isValidColor(color)) {
            final colorKey = color.value;
            colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
          }
        }
      }

      if (colorCounts.isEmpty) return [Colors.deepPurple];

      // Sort by frequency and take top colors
      final sortedColors = colorCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      return sortedColors
          .take(maxColors)
          .map((entry) => Color(entry.key))
          .toList();
    } catch (e) {
      print('Error extracting palette: $e');
      return [Colors.deepPurple];
    }
  }

  /// Generate complementary colors for theming
  List<Color> generateThemeColors(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    
    return [
      baseColor, // Primary
      hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor(), // Light
      hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor(), // Dark
      hsl.withHue((hsl.hue + 180) % 360).toColor(), // Complementary
      hsl.withSaturation((hsl.saturation * 0.7).clamp(0.0, 1.0)).toColor(), // Muted
    ];
  }

  Color _pixelToColor(img.Pixel pixel) {
    return Color.fromARGB(
      255, // Full opacity
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
  }

  bool _isValidColor(Color color) {
    // Skip very dark colors (brightness < 0.1)
    // Skip very light colors (brightness > 0.9)
    // Skip very desaturated colors
    final hsl = HSLColor.fromColor(color);
    return hsl.lightness > 0.1 && 
           hsl.lightness < 0.9 && 
           hsl.saturation > 0.2;
  }

  /// Extract color from network image
  Future<Color> extractFromNetworkImage(String imageUrl) async {
    try {
      // This would typically use http to fetch the image
      // For now, return a default color
      return Colors.deepPurple;
    } catch (e) {
      return Colors.deepPurple;
    }
  }

  /// Create adaptive theme based on extracted color
  ThemeData createAdaptiveTheme(Color primaryColor, {bool isDark = false}) {
    final colors = generateThemeColors(primaryColor);
    
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primarySwatch: _createMaterialColor(primaryColor),
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: _getContrastColor(primaryColor),
      ),
    );
  }

  MaterialColor _createMaterialColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final shades = <int, Color>{};
    
    for (int i = 1; i <= 9; i++) {
      final lightness = (hsl.lightness * (10 - i) / 10).clamp(0.0, 1.0);
      shades[i * 100] = hsl.withLightness(lightness).toColor();
    }
    
    return MaterialColor(color.value, shades);
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance and return black or white for best contrast
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}