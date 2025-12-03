"""
BantayBayan Flood Risk Model Converter
Converts scikit-learn RandomForest models to TensorFlow Lite format

Requirements:
    pip install scikit-learn tensorflow numpy joblib

Usage:
    python convert_models_to_tflite.py
"""

import pickle
import numpy as np
import tensorflow as tf
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
import os

# Configuration
MODEL_DIR = "models"  # Directory containing .pkl files
OUTPUT_DIR = "assets/ml_models"  # Output directory for .tflite files

# File paths
PROBABILITY_MODEL_PATH = os.path.join(MODEL_DIR, "flood_probability_model.pkl")
DEPTH_MODEL_PATH = os.path.join(MODEL_DIR, "flood_depth_model.pkl")
SCALER_PATH = os.path.join(MODEL_DIR, "feature_scaler.pkl")

# Feature columns (must match training)
FEATURE_COLUMNS = [
    'elevation', 'slope', 'flow_accumulation', 
    'dist_to_road', 'population', 'dist_to_landslide'
]


class RandomForestToTFLite:
    """Convert scikit-learn RandomForest to TensorFlow Lite model"""
    
    def __init__(self, rf_model, feature_scaler=None):
        self.rf_model = rf_model
        self.feature_scaler = feature_scaler
        self.n_features = rf_model.n_features_in_
        self.n_trees = len(rf_model.estimators_)
        
    def extract_tree_parameters(self):
        """Extract decision tree parameters from RandomForest"""
        trees_data = []
        
        for tree_idx, tree in enumerate(self.rf_model.estimators_):
            tree_structure = tree.tree_
            
            # Extract tree parameters
            trees_data.append({
                'children_left': tree_structure.children_left,
                'children_right': tree_structure.children_right,
                'feature': tree_structure.feature,
                'threshold': tree_structure.threshold,
                'value': tree_structure.value.squeeze(),
                'n_node_samples': tree_structure.n_node_samples
            })
        
        return trees_data
    
    def build_keras_model(self):
        """
        Build a Keras model that mimics RandomForest behavior.
        Note: This is a simplified approach. For production, consider using
        tree ensemble layers or custom operations.
        """
        # Input layer (6 features)
        inputs = tf.keras.Input(shape=(self.n_features,), name='features')
        
        # For simplicity, we'll create a neural network approximation
        # In production, you'd want to use proper tree ensemble conversion
        x = inputs
        
        # Hidden layers to approximate tree ensemble
        x = tf.keras.layers.Dense(128, activation='relu')(x)
        x = tf.keras.layers.Dense(64, activation='relu')(x)
        x = tf.keras.layers.Dense(32, activation='relu')(x)
        
        # Output layer
        outputs = tf.keras.layers.Dense(1, activation='linear')(x)
        
        model = tf.keras.Model(inputs=inputs, outputs=outputs)
        
        return model
    
    def train_approximation_model(self, n_samples=10000):
        """
        Train a neural network to approximate the RandomForest predictions
        This is necessary because TFLite doesn't natively support RandomForest
        """
        print(f"Generating {n_samples} synthetic samples for approximation...")
        
        # Generate synthetic data covering the feature space
        # You should replace this with actual training data if available
        X_synthetic = np.random.randn(n_samples, self.n_features).astype(np.float32)
        
        # Apply feature scaling if available
        if self.feature_scaler:
            X_synthetic = self.feature_scaler.transform(X_synthetic)
        
        # Get RandomForest predictions as training labels
        y_synthetic = self.rf_model.predict(X_synthetic).astype(np.float32)
        
        # Build approximation model
        model = self.build_keras_model()
        
        # Compile model
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
            loss='mse',
            metrics=['mae']
        )
        
        # Train the approximation
        print("Training neural network approximation...")
        model.fit(
            X_synthetic, y_synthetic,
            epochs=50,
            batch_size=32,
            validation_split=0.2,
            verbose=1
        )
        
        return model
    
    def convert_to_tflite(self, output_path, quantize=True):
        """Convert the model to TensorFlow Lite format"""
        
        # Train approximation model
        keras_model = self.train_approximation_model()
        
        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)
        
        if quantize:
            # Apply dynamic range quantization to reduce model size
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            # Use float16 quantization for better accuracy
            converter.target_spec.supported_types = [tf.float16]
        
        tflite_model = converter.convert()
        
        # Save the model
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        print(f"Model saved to {output_path}")
        print(f"Model size: {len(tflite_model) / 1024:.2f} KB")
        
        return tflite_model


def save_scaler_parameters(scaler, output_path):
    """
    Save scaler parameters as a simple JSON/text file for Flutter
    This allows us to apply scaling in Dart without TFLite
    """
    import json
    
    scaler_params = {
        'mean': scaler.mean_.tolist(),
        'scale': scaler.scale_.tolist(),
        'feature_columns': FEATURE_COLUMNS
    }
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(scaler_params, f, indent=2)
    
    print(f"Scaler parameters saved to {output_path}")


def validate_conversion(original_model, tflite_path, scaler=None, n_test_samples=100):
    """Validate that TFLite model produces similar outputs to original"""
    
    # Load TFLite model
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # Generate test samples
    X_test = np.random.randn(n_test_samples, 6).astype(np.float32)
    
    if scaler:
        X_test_scaled = scaler.transform(X_test)
    else:
        X_test_scaled = X_test
    
    # Get original predictions
    original_predictions = original_model.predict(X_test_scaled)
    
    # Get TFLite predictions
    tflite_predictions = []
    for sample in X_test_scaled:
        interpreter.set_tensor(input_details[0]['index'], sample.reshape(1, -1))
        interpreter.invoke()
        pred = interpreter.get_tensor(output_details[0]['index'])[0][0]
        tflite_predictions.append(pred)
    
    tflite_predictions = np.array(tflite_predictions)
    
    # Calculate error metrics
    mae = np.mean(np.abs(original_predictions - tflite_predictions))
    mse = np.mean((original_predictions - tflite_predictions) ** 2)
    
    print(f"\nValidation Results:")
    print(f"  MAE: {mae:.6f}")
    print(f"  MSE: {mse:.6f}")
    print(f"  Max Error: {np.max(np.abs(original_predictions - tflite_predictions)):.6f}")
    
    return mae, mse


def main():
    """Main conversion pipeline"""
    
    print("=" * 70)
    print("BantayBayan ML Model Converter: RandomForest → TensorFlow Lite")
    print("=" * 70)
    
    # Load models
    print("\n[1/5] Loading scikit-learn models...")
    
    try:
        with open(PROBABILITY_MODEL_PATH, 'rb') as f:
            probability_model = pickle.load(f)
        print(f"  ✓ Loaded flood probability model ({probability_model.n_estimators} trees)")
        
        with open(DEPTH_MODEL_PATH, 'rb') as f:
            depth_model = pickle.load(f)
        print(f"  ✓ Loaded flood depth model ({depth_model.n_estimators} trees)")
        
        with open(SCALER_PATH, 'rb') as f:
            scaler = pickle.load(f)
        print(f"  ✓ Loaded feature scaler")
        
    except FileNotFoundError as e:
        print(f"\n❌ Error: Model file not found - {e}")
        print(f"Please ensure model files are in the '{MODEL_DIR}/' directory")
        return
    
    # Save scaler parameters for Flutter
    print("\n[2/5] Saving scaler parameters...")
    save_scaler_parameters(scaler, os.path.join(OUTPUT_DIR, "scaler_params.json"))
    
    # Convert probability model
    print("\n[3/5] Converting flood probability model...")
    prob_converter = RandomForestToTFLite(probability_model, scaler)
    prob_tflite_path = os.path.join(OUTPUT_DIR, "flood_probability_model.tflite")
    prob_converter.convert_to_tflite(prob_tflite_path, quantize=True)
    
    # Convert depth model
    print("\n[4/5] Converting flood depth model...")
    depth_converter = RandomForestToTFLite(depth_model, scaler)
    depth_tflite_path = os.path.join(OUTPUT_DIR, "flood_depth_model.tflite")
    depth_converter.convert_to_tflite(depth_tflite_path, quantize=True)
    
    # Validate conversions
    print("\n[5/5] Validating conversions...")
    print("\nFlood Probability Model:")
    validate_conversion(probability_model, prob_tflite_path, scaler)
    
    print("\nFlood Depth Model:")
    validate_conversion(depth_model, depth_tflite_path, scaler)
    
    print("\n" + "=" * 70)
    print("✅ Conversion Complete!")
    print("=" * 70)
    print(f"\nOutput files:")
    print(f"  • {prob_tflite_path}")
    print(f"  • {depth_tflite_path}")
    print(f"  • {os.path.join(OUTPUT_DIR, 'scaler_params.json')}")
    print(f"\nNext steps:")
    print(f"  1. Copy these files to your Flutter project's assets/ml_models/ directory")
    print(f"  2. Update pubspec.yaml to include these assets")
    print(f"  3. Use the TFLiteInferenceService in Flutter to load and run inference")
    

if __name__ == "__main__":
    main()
