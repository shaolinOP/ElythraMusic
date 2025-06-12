import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/services/color_extraction_service.dart';
import 'package:http/http.dart' as http;

Future<Color> getPalleteFromImage(String url) async {
  try {
    final colorService = ColorExtractionService();
    
    // Fetch image from network
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return await colorService.extractDominantColor(response.bodyBytes);
    } else {
      // Fallback to default color
      return Colors.deepPurple;
    }
  } catch (e) {
    // Return default color on error
    return Colors.deepPurple;
  }
}
