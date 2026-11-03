import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:summarizit/utils/constants.dart';

class DocumentScannerService {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> pickAndExtractTextFromImage(ImageSource source) async {
    try {
      if (kIsWeb) {
        return null;
      }

      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return null;

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e, st) {
      debugPrint('Error picking or recognizing text from image: $e\n$st');
      return null;
    }
  }

  /// Picks a .txt file, validates its size, and returns its contents.
  ///
  /// Returns `null` if no file was selected, or an error description string
  /// starting with "Error:" if the file exceeds the size limit.
  Future<String?> pickAndExtractTextFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.single;

      // Guard against oversized files to prevent OOM.
      if (file.size > AppConstants.maxFileBytes) {
        final limitMB = AppConstants.maxFileBytes ~/ (1024 * 1024);
        return 'Error: File is too large (${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB). '
            'Maximum allowed size is $limitMB MB.';
      }

      // On web, path is null; use bytes instead.
      if (kIsWeb && file.bytes != null) {
        return utf8.decode(file.bytes!);
      } else if (file.path != null) {
        return await File(file.path!).readAsString();
      }
      return null;
    } catch (e, st) {
      debugPrint('Error picking or reading text file: $e\n$st');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
