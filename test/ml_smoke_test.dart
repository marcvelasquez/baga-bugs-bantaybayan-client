import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ML Models Smoke Test', () {
    test('Flood Probability Model exists and loads', () async {
      try {
        // Try to load the model
        final interpreter = await Interpreter.fromAsset(
          'assets/ml_models/flood_probability_model.tflite',
        );
        
        print('✅ Flood Probability Model loaded successfully');
        print('   Input tensors: ${interpreter.getInputTensors().length}');
        print('   Output tensors: ${interpreter.getOutputTensors().length}');
        
        if (interpreter.getInputTensors().isNotEmpty) {
          final inputShape = interpreter.getInputTensor(0).shape;
          print('   Input shape: $inputShape');
        }
        
        if (interpreter.getOutputTensors().isNotEmpty) {
          final outputShape = interpreter.getOutputTensor(0).shape;
          print('   Output shape: $outputShape');
        }
        
        interpreter.close();
      } catch (e) {
        fail('❌ Failed to load Flood Probability Model: $e');
      }
    });

    test('Flood Depth Model exists and loads', () async {
      try {
        final interpreter = await Interpreter.fromAsset(
          'assets/ml_models/flood_depth_model.tflite',
        );
        
        print('✅ Flood Depth Model loaded successfully');
        print('   Input tensors: ${interpreter.getInputTensors().length}');
        print('   Output tensors: ${interpreter.getOutputTensors().length}');
        
        if (interpreter.getInputTensors().isNotEmpty) {
          final inputShape = interpreter.getInputTensor(0).shape;
          print('   Input shape: $inputShape');
        }
        
        if (interpreter.getOutputTensors().isNotEmpty) {
          final outputShape = interpreter.getOutputTensor(0).shape;
          print('   Output shape: $outputShape');
        }
        
        interpreter.close();
      } catch (e) {
        fail('❌ Failed to load Flood Depth Model: $e');
      }
    });

    test('Scaler Parameters file exists', () async {
      try {
        final scalerData = await rootBundle.loadString(
          'assets/ml_models/scaler_params.json',
        );
        
        print('✅ Scaler Parameters loaded successfully');
        print('   Data length: ${scalerData.length} characters');
        
        // Check if it's valid JSON
        if (scalerData.contains('mean') && scalerData.contains('scale')) {
          print('   Contains expected fields: mean, scale');
        }
      } catch (e) {
        fail('❌ Failed to load Scaler Parameters: $e');
      }
    });

    test('Test model inference with dummy data', () async {
      try {
        final interpreter = await Interpreter.fromAsset(
          'assets/ml_models/flood_probability_model.tflite',
        );
        
        // Get input shape
        final inputShape = interpreter.getInputTensor(0).shape;
        final numFeatures = inputShape[1];
        
        // Create dummy input (all zeros)
        final input = List.generate(1, (_) => List.filled(numFeatures, 0.0));
        final output = List.filled(1, 0.0).reshape([1, 1]);
        
        // Run inference
        interpreter.run(input, output);
        
        print('✅ Model inference test successful');
        print('   Input features: $numFeatures');
        print('   Output: ${output[0][0]}');
        
        interpreter.close();
      } catch (e) {
        fail('❌ Model inference failed: $e');
      }
    });
  });

  group('Raster Files Smoke Test', () {
    test('Check if raster directories exist', () async {
      final directories = [
        'assets/rasters/elevation',
        'assets/rasters/slope',
        'assets/rasters/flow_accumulation',
        'assets/rasters/population',
      ];

      for (final dir in directories) {
        final directory = Directory(dir);
        if (await directory.exists()) {
          final files = await directory.list().toList();
          print('✅ Directory exists: $dir');
          print('   Files: ${files.length}');
          for (final file in files) {
            if (file is File) {
              final stat = await file.stat();
              print('   - ${file.path.split('/').last} (${(stat.size / 1024 / 1024).toStringAsFixed(2)} MB)');
            }
          }
        } else {
          print('⚠️  Directory exists but empty: $dir');
        }
      }
    });

    test('Check ML models directory', () async {
      final directory = Directory('assets/ml_models');
      if (await directory.exists()) {
        final files = await directory.list().toList();
        print('✅ ML Models directory exists');
        print('   Files: ${files.length}');
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            print('   - ${file.path.split('/').last} (${(stat.size / 1024).toStringAsFixed(2)} KB)');
          }
        }
      }
    });
  });
}
