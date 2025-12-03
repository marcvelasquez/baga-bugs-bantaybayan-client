import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:convert';

class FloodPrediction {
  final double probability;
  final double depthCm;
  final String riskLevel;

  FloodPrediction({
    required this.probability,
    required this.depthCm,
    required this.riskLevel,
  });

  String get riskLevelText {
    if (riskLevel == 'CRITICAL') return '🔴 CRITICAL';
    if (riskLevel == 'HIGH') return '🟠 HIGH';
    if (riskLevel == 'MODERATE') return '🟡 MODERATE';
    return '🟢 LOW';
  }
}

class MLPredictionService {
  static Interpreter? _probabilityModel;
  static Interpreter? _depthModel;
  static Map<String, dynamic>? _scalerParams;
  static bool _isInitialized = false;

  /// Initialize ML models
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Load scaler parameters
      final scalerJson = await rootBundle.loadString('assets/ml_models/scaler_params.json');
      _scalerParams = jsonDecode(scalerJson);

      // Load TFLite models
      _probabilityModel = await Interpreter.fromAsset('assets/ml_models/flood_probability_model.tflite');
      _depthModel = await Interpreter.fromAsset('assets/ml_models/flood_depth_model.tflite');

      _isInitialized = true;
      print('✅ ML models initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error initializing ML models: $e');
      return false;
    }
  }

  /// Dispose of models to free memory
  static void dispose() {
    _probabilityModel?.close();
    _depthModel?.close();
    _probabilityModel = null;
    _depthModel = null;
    _isInitialized = false;
  }

  /// Normalize input features using scaler parameters
  static List<double> _normalizeInput(List<double> rawInput) {
    if (_scalerParams == null) {
      throw Exception('Scaler parameters not loaded');
    }

    final mean = List<double>.from(_scalerParams!['mean']);
    final scale = List<double>.from(_scalerParams!['scale']);

    return List<double>.generate(
      rawInput.length,
      (i) => (rawInput[i] - mean[i]) / scale[i],
    );
  }

  /// Make flood prediction for given features
  /// Features: [elevation, slope, flow_accumulation, distance_to_water, population, rainfall]
  static Future<FloodPrediction?> predict({
    required double elevation,
    required double slope,
    required double flowAccumulation,
    required double distanceToWater,
    required double population,
    required double rainfall,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    try {
      // Prepare input features
      final rawInput = [
        elevation,
        slope,
        flowAccumulation,
        distanceToWater,
        population,
        rainfall,
      ];

      // Normalize input
      final normalizedInput = _normalizeInput(rawInput);

      // Prepare for model (batch size = 1)
      final input = [normalizedInput];

      // Run flood probability prediction
      final probabilityOutput = List.filled(1, 0.0).reshape([1, 1]);
      _probabilityModel!.run(input, probabilityOutput);
      final probability = probabilityOutput[0][0];

      // Run flood depth prediction
      final depthOutput = List.filled(1, 0.0).reshape([1, 1]);
      _depthModel!.run(input, depthOutput);
      final depth = depthOutput[0][0];

      // Determine risk level
      String riskLevel;
      if (probability >= 0.7 || depth >= 50) {
        riskLevel = 'CRITICAL';
      } else if (probability >= 0.5 || depth >= 30) {
        riskLevel = 'HIGH';
      } else if (probability >= 0.3 || depth >= 15) {
        riskLevel = 'MODERATE';
      } else {
        riskLevel = 'LOW';
      }

      return FloodPrediction(
        probability: probability,
        depthCm: depth,
        riskLevel: riskLevel,
      );
    } catch (e) {
      print('Error making prediction: $e');
      return null;
    }
  }

  /// Make predictions for storm scenario (high rainfall)
  static Future<FloodPrediction?> predictForStorm({
    required double rainfall,
    double elevation = 100.0,
    double slope = 5.0,
    double flowAccumulation = 1000.0,
    double distanceToWater = 500.0,
    double population = 1000.0,
  }) async {
    return predict(
      elevation: elevation,
      slope: slope,
      flowAccumulation: flowAccumulation,
      distanceToWater: distanceToWater,
      population: population,
      rainfall: rainfall,
    );
  }

  /// Check if models are ready
  static bool get isReady => _isInitialized;
}
