import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your actual backend API URL
  final String _baseUrl = 'https://your-backend-api.com';

  Future<String> processDetections(
      List<Map<String, dynamic>> detections) async {
    try {
      // Prepare data for API
      final data = {
        'detections': detections
            .map((detection) => {
                  'label': detection['label'],
                  'confidence': detection['confidence'],
                  'position': {
                    'x': detection['rect'].left,
                    'y': detection['rect'].top,
                    'width': detection['rect'].width,
                    'height': detection['rect'].height,
                  },
                })
            .toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // For demo purposes, we'll return a mock response
      // In a real app, you would uncomment the HTTP request below

      /*
      final response = await http.post(
        Uri.parse('$_baseUrl/process-detections'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['description'] as String;
      } else {
        throw Exception('Failed to process detections: ${response.statusCode}');
      }
      */

      // Mock response for demo
      return _generateMockDescription(detections);
    } catch (e) {
      print('Error calling API: $e');
      return "I can see some objects around you.";
    }
  }

  String _generateMockDescription(List<Map<String, dynamic>> detections) {
    if (detections.isEmpty) {
      return "I don't see any objects clearly right now.";
    }

    // Sort by confidence
    final sortedDetections = List<Map<String, dynamic>>.from(detections)
      ..sort((a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double));

    // Take top 3
    final topDetections = sortedDetections.take(3).toList();

    if (topDetections.length == 1) {
      final detection = topDetections[0];
      return "I can see a ${detection['label']} in front of you.";
    } else {
      final objects = topDetections.map((d) => d['label']).join(', ');
      return "I can see these objects: $objects.";
    }
  }
}
