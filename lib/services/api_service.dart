import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui';

class ApiService {
  final String _baseUrl = 'https://visionai-backend.onrender.com';

  Future<String> processDetections(
      List<Map<String, dynamic>> detections) async {
    try {
      // Count occurrences of each object
      final Map<String, int> objectCounts = {};
      final Map<String, double> objectConfidences = {};
      final Map<String, List<List<double>>> objectPositions = {};

      for (final detection in detections) {
        final label = detection['label'] as String;
        final confidence = detection['confidence'] as double;
        final rect = detection['rect'] as Rect;

        // Update counts
        objectCounts[label] = (objectCounts[label] ?? 0) + 1;

        // Update average confidence
        objectConfidences[label] = (objectConfidences[label] ?? 0) + confidence;

        // Store position as a list (tuple)
        objectPositions[label] = objectPositions[label] ?? [];
        objectPositions[label]!.add([
          rect.left + (rect.width / 2), // center x
          rect.top + (rect.height / 2), // center y
        ]);
      }

      // Calculate average confidences
      objectConfidences.forEach((key, value) {
        objectConfidences[key] = value / objectCounts[key]!;
      });

      // Prepare data for API
      final data = {
        'objects': objectCounts.keys
            .map((label) => {
                  'label': label,
                  'count': objectCounts[label],
                  'confidence': objectConfidences[label],
                  'positions': objectPositions[label],
                })
            .toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      print("data: $data");
      final response = await http.post(
        Uri.parse('$_baseUrl/narrate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      print("response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['narration'] as String;
      } else {
        throw Exception('Failed to process scene: ${response.statusCode}');
      }
      //throw Exception('Failed to process scene:');
    } catch (e) {
      print('Error calling API: $e');
      return "I can see some objects around you, but I'm having trouble describing the scene in detail.";
    }
  }

  String _generateSceneDescription(Map<String, int> objectCounts,
      Map<String, List<Map<String, double>>> objectPositions) {
    if (objectCounts.isEmpty) {
      return "I don't see any objects clearly around you right now.";
    }

    // Sort objects by count
    final sortedObjects = objectCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 most common objects
    final topObjects = sortedObjects.take(5).toList();

    // Generate basic description
    String description = "Around you, I can see ";

    // Add object counts
    for (int i = 0; i < topObjects.length; i++) {
      final entry = topObjects[i];
      final objectName = entry.key;
      final count = entry.value;

      // Determine position words based on average position
      String positionWord = _determinePosition(objectPositions[objectName]!);

      if (i == 0) {
        description +=
            "$count $objectName${count > 1 ? 's' : ''} $positionWord";
      } else if (i == topObjects.length - 1) {
        description +=
            " and $count $objectName${count > 1 ? 's' : ''} $positionWord";
      } else {
        description +=
            ", $count $objectName${count > 1 ? 's' : ''} $positionWord";
      }
    }

    description += ".";

    // Add some context if we have enough objects
    if (topObjects.length >= 3) {
      if (objectCounts.containsKey('person') && objectCounts['person']! > 1) {
        description += " It looks like you might be in a crowded area.";
      } else if (objectCounts.containsKey('car') ||
          objectCounts.containsKey('truck') ||
          objectCounts.containsKey('bus')) {
        description += " You appear to be near a road or parking area.";
      } else if (objectCounts.containsKey('chair') &&
          objectCounts.containsKey('table')) {
        description += " You might be in a dining area or restaurant.";
      } else if (objectCounts.containsKey('book') ||
          objectCounts.containsKey('laptop')) {
        description += " You seem to be in a study area or office.";
      }
    }

    return description;
  }

  String _determinePosition(List<Map<String, double>> positions) {
    if (positions.isEmpty) return "";

    // Calculate average position
    double avgX = 0;
    double avgY = 0;

    for (final pos in positions) {
      avgX += pos['x']!;
      avgY += pos['y']!;
    }

    avgX /= positions.length;
    avgY /= positions.length;

    // Determine horizontal position
    String horizontalPos = "";
    if (avgX < 0.33) {
      horizontalPos = "to your left";
    } else if (avgX > 0.66) {
      horizontalPos = "to your right";
    } else {
      horizontalPos = "in front of you";
    }

    // Determine vertical position
    String verticalPos = "";
    if (avgY < 0.33) {
      verticalPos = "above";
    } else if (avgY > 0.66) {
      verticalPos = "below";
    }

    // Combine positions
    if (verticalPos.isNotEmpty) {
      return "$verticalPos and $horizontalPos";
    } else {
      return horizontalPos;
    }
  }
}
