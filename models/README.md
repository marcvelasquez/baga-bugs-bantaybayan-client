# Model Files Directory

Place your trained scikit-learn model files here before running the conversion script.

## Required Files:

1. **flood_probability_model.pkl** (~15MB)
   - Your trained RandomForest model for flood probability prediction

2. **flood_depth_model.pkl** (~15MB)
   - Your trained RandomForest model for flood depth prediction

3. **feature_scaler.pkl** (<1KB)
   - StandardScaler used during training

4. **feature_columns.txt** (optional)
   - List of feature names in order:
     ```
     elevation
     slope
     flow_accumulation
     dist_to_road
     population
     dist_to_landslide
     ```

## Raster Data Files (if available):

5. **philippines_elevation_merged.tif**
   - NASADEM 30m elevation data

6. **philippines_slope_merged.tif**
   - Slope in degrees

7. **pampanga_flow_accumulation.tif**
   - HydroSHEDS flow accumulation

8. **phl_ppp_2020.tif**
   - WorldPop population density

## Vector Data Files:

9. **philippines-251202-free.shp/** (folder)
   - OSM roads shapefile

10. **philippines_landslides.csv**
    - NASA landslide database

## After Adding Files:

Run the conversion script:
```bash
cd scripts
python convert_models_to_tflite.py
```

This will generate TFLite models in `assets/ml_models/`:
- flood_probability_model.tflite
- flood_depth_model.tflite
- scaler_params.json
