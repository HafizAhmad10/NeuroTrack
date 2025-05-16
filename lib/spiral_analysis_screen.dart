import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SpiralAnalysisScreen extends StatefulWidget {
  @override
  _SpiralAnalysisScreenState createState() => _SpiralAnalysisScreenState();
}

class _SpiralAnalysisScreenState extends State<SpiralAnalysisScreen> {
  int _currentStep = 0;
  File? _imageFile;
  String _analysisResult = '';
  bool _isAnalyzing = false;
  Interpreter? _interpreter;

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final manifest = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      if (!manifest.contains('models/spiral_model01.tflite')) {
        throw Exception('Model file not found in assets');
      }

      _interpreter = await Interpreter.fromAsset('models/spiral_model01.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
      setState(() {
        _analysisResult = 'Error: Could not load analysis engine. Please reinstall the app.';
      });
      rethrow;
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Image Source"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text("Take Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text("Choose from Gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _currentStep = 2; // Move to analysis step
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null || _interpreter == null) {
      setState(() {
        _analysisResult = 'Error: Model not loaded or no image selected';
        _isAnalyzing = false;
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final imageBytes = await _imageFile!.readAsBytes();
      final image = img.decodeImage(imageBytes)!;
      final resizedImage = img.copyResize(image, width: 224, height: 224);
      final imageMatrix = List.generate(224, (i) =>
          List.generate(224, (j) {
            final pixel = resizedImage.getPixel(j, i);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          })
      );

      final input = [imageMatrix];
      final output = List.filled(1, 0).reshape([1, 1]);
      _interpreter!.run(input, output);

      final probability = output[0][0];
      _analysisResult = _generateReport(probability);

    } catch (e) {
      _analysisResult = 'Error analyzing image: ${e.toString()}';
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  String _generateReport(double probability) {
    if (probability < 0.2) {
      return '''
🧠 Patient's Condition: Normal
📝 Parkinson's Analysis Report
----------------------------------
🧪 Parkinson's Signs: ${(probability * 100).toStringAsFixed(2)}%
🔍 Confidence: High confidence
📊 Estimated Stage: Normal / Healthy
🩺 Possible Symptoms: No significant signs of Parkinson's detected.
💊 Suggested Action: No immediate treatment required. Regular checkups recommended.
----------------------------------
⚠️ Note: This analysis is not a definitive diagnosis. Always consult with a medical professional.
''';
    } else if (probability < 0.4) {
      return '''
🧠 Patient's Condition: Normal (Borderline)
📝 Parkinson's Analysis Report
----------------------------------
🧪 Parkinson's Signs: ${(probability * 100).toStringAsFixed(2)}%
🔍 Confidence: Moderate confidence
📊 Estimated Stage: Possible Early Signs (Stage 0-1)
🩺 Possible Symptoms: Very mild signs that could be early indicators or normal variations.
💊 Suggested Action: Monitor for changes. Consider neurological evaluation if symptoms persist.
----------------------------------
⚠️ Note: This analysis is not a definitive diagnosis. Always consult with a medical professional.
''';
    } else if (probability < 0.6) {
      return '''
🧠 Patient's Condition: Early Signs Detected
📝 Parkinson's Analysis Report
----------------------------------
🧪 Parkinson's Signs: ${(probability * 100).toStringAsFixed(2)}%
🔍 Confidence: Low confidence
📊 Estimated Stage: Potential Early Parkinson's (Stage 1-2)
🩺 Possible Symptoms: Mild tremors, slight motor delays detected.
💊 Suggested Action: Clinical evaluation recommended. Consider mild therapy and lifestyle adjustments.
----------------------------------
⚠️ Note: This analysis is not a definitive diagnosis. Always consult with a medical professional.
''';
    } else if (probability < 0.8) {
      return '''
🧠 Patient's Condition: Likely Parkinson's
📝 Parkinson's Analysis Report
----------------------------------
🧪 Parkinson's Signs: ${(probability * 100).toStringAsFixed(2)}%
🔍 Confidence: Moderate confidence
📊 Estimated Stage: Moderate Parkinson's (Stage 2-3)
🩺 Possible Symptoms: Noticeable tremors, coordination issues detected.
💊 Suggested Action: Neurologist consultation strongly recommended. Medication may be beneficial.
----------------------------------
⚠️ Note: This analysis is not a definitive diagnosis. Always consult with a medical professional.
''';
    } else {
      return '''
🧠 Patient's Condition: High Risk Parkinson's
📝 Parkinson's Analysis Report
----------------------------------
🧪 Parkinson's Signs: ${(probability * 100).toStringAsFixed(2)}%
🔍 Confidence: High confidence
📊 Estimated Stage: Advanced Parkinson's (Stage 3-5)
🩺 Possible Symptoms: Severe tremors, significant motor impairment detected.
💊 Suggested Action: Immediate neurological evaluation required. Advanced treatment options needed.
----------------------------------
⚠️ Note: This analysis is not a definitive diagnosis. Always consult with a medical professional.
''';
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep += 1;
      });
    } else if (_currentStep == 2) {
      _analyzeImage();
    }
  }

  void _resetProcess() {
    setState(() {
      _currentStep = 0;
      _imageFile = null;
      _analysisResult = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spiral Drawing Analysis'),
        backgroundColor: Colors.blue,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _currentStep == 0 ? null : () {
          setState(() {
            _currentStep -= 1;
          });
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentStep != 0)
                  ElevatedButton(
                    onPressed: details.onStepCancel,
                    child: Text('Back'),
                  ),
                if (_currentStep != 0)
                  SizedBox(width: 12),
                if (_currentStep < 2)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text('Next'),
                  ),
                if (_currentStep == 2 && !_isAnalyzing)
                  ElevatedButton(
                    onPressed: _imageFile != null ? details.onStepContinue : null,
                    child: Text('Analyze'),
                  ),
              ],
            ),
          );
        },

        steps: [
          Step(
            title: Text('Step 1: Draw the Spiral'),
            content: Column(
              children: [
                Text('Please draw the following spiral on paper:'),
                SizedBox(height: 20),
                Image.asset('images/spiral.png'),
                SizedBox(height: 20),
                Text('Take a clear photo of your drawing for analysis.'),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: Text('Step 2: Upload Your Drawing'),
            content: Column(
              children: [
                if (_imageFile != null)
                  Image.file(_imageFile!, height: 200)
                else
                  Text('No image selected'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showImageSourceDialog,
                  child: Text('Select Image'),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: Text('Step 3: Analysis Results'),
            content: _isAnalyzing
                ? Column(
              children: [
                SizedBox(height: 40),
                SpinKitFadingCircle(
                  color: Colors.blue,
                  size: 50.0,
                ),
                SizedBox(height: 20),
                Text('Analyzing your drawing...'),
              ],
            )
                : _analysisResult.isNotEmpty
                ? SingleChildScrollView(
              child: Text(
                _analysisResult,
                style: TextStyle(fontSize: 16),
              ),
            )
                : Text('Press "Analyze" to start analysis'),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
      floatingActionButton: _currentStep == 2 && _analysisResult.isNotEmpty
          ? FloatingActionButton(
        onPressed: _resetProcess,
        child: Icon(Icons.refresh),
        tooltip: 'Start Over',
      )
          : null,
    );
  }
}