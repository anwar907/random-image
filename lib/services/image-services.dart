import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

class ImageServices {
  static Future<String> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('https://november7-730026606190.europe-west1.run.app/image/'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        log(' ${result['url']}');
        return result['url'];
      } else if (response.statusCode == 404) {
        throw Exception('Image not found (404)');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format');
      }
      rethrow;
    }
  }
}
