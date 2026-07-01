import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb

class DocumentScannerService {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> pickAndExtractTextFromImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return null;

      // Google ML Kit doesn't support web natively via this plugin, fallback to simple placeholder or avoid calling
      if (kIsWeb) {
         return "OCR is currently not supported on Web in this demo.";
      }

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      // ignore
      return null;
    }
  }

  Future<String?> pickAndExtractTextFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      // Ignore in production
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
