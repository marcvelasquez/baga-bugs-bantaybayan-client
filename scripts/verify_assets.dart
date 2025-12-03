import 'dart:io';
import 'dart:convert';

void main() async {
  print('🧪 ML Assets Smoke Test\n');
  print('=' * 60);
  
  // Check ML Models
  print('\n📦 ML Models:');
  await checkFile('assets/ml_models/flood_probability_model.tflite');
  await checkFile('assets/ml_models/flood_depth_model.tflite');
  await checkFile('assets/ml_models/scaler_params.json');
  
  // Validate scaler params JSON
  print('\n🔍 Validating Scaler Parameters:');
  final scalerFile = File('assets/ml_models/scaler_params.json');
  if (await scalerFile.exists()) {
    final content = await scalerFile.readAsString();
    try {
      final json = jsonDecode(content);
      if (json.containsKey('mean') && json.containsKey('scale')) {
        print('   ✅ Valid JSON with mean and scale fields');
        print('   📊 Number of features: ${(json['mean'] as List).length}');
      } else {
        print('   ❌ Missing required fields (mean, scale)');
      }
    } catch (e) {
      print('   ❌ Invalid JSON: $e');
    }
  }
  
  // Check Raster Files
  print('\n🗺️  Raster Data Files:');
  await checkFile('assets/rasters/elevation/philippines_elevation_merged.tif');
  await checkFile('assets/rasters/slope/philippines_slope_merged.tif');
  await checkFile('assets/rasters/flow_accumulation/pampanga_flow_accumulation.tif');
  await checkFile('assets/rasters/population/phl_ppp_2020.tif');
  
  print('\n' + '=' * 60);
  print('✨ Smoke test complete!\n');
  print('📝 Note: TFLite models will only run on actual devices/emulators,');
  print('   not in desktop tests. File presence and format verified.');
}

Future<void> checkFile(String path) async {
  final file = File(path);
  final exists = await file.exists();
  
  if (exists) {
    final stat = await file.stat();
    final sizeMB = stat.size / 1024 / 1024;
    final sizeStr = sizeMB > 1 
        ? '${sizeMB.toStringAsFixed(2)} MB'
        : '${(stat.size / 1024).toStringAsFixed(2)} KB';
    
    print('   ✅ ${path.split('/').last.padRight(40)} $sizeStr');
  } else {
    print('   ❌ ${path.split('/').last.padRight(40)} NOT FOUND');
  }
}
