import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

final objectDetectionServiceProvider = Provider((ref) => ObjectDetectionService());

class ObjectDetectionService {
  late final ObjectDetector _objectDetector;

  ObjectDetectionService() {
    _initDetector();
  }

  void _initDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<List<Map<String, dynamic>>> detectObject(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final objects = await _objectDetector.processImage(inputImage);

      if (objects.isEmpty) {
        return [{'label': 'No Part Recognized', 'confidence': 0.0}];
      }

      final firstObject = objects.first;
      String label = 'Unknown Part';
      double confidence = 0.0;

      if (firstObject.labels.isNotEmpty) {
        label = firstObject.labels.first.text;
        confidence = firstObject.labels.first.confidence;
      }

      return [
        {
          'label': label,
          'confidence': confidence,
        }
      ];
    } catch (e) {
      return [{'label': 'Error: ${e.toString().split('\n').first}', 'confidence': 0.0}];
    }
  }

  void dispose() {
    _objectDetector.close();
  }
}
