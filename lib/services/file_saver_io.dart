import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

Future<String?> saveFileSafely(
  List<int> bytes,
  String fileName,
  String extension,
) async {
  // Ensure extension doesn't have a leading dot for the picker
  final cleanExt = extension.startsWith('.')
      ? extension.substring(1)
      : extension;

  String? path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save File',
    fileName: '$fileName.$cleanExt',
    type: FileType.custom,
    allowedExtensions: [cleanExt],
  );

  // User cancelled the save dialog
  if (path == null) return null;

  // Final check to ensure extension is present, case-insensitively
  if (!path.toLowerCase().endsWith('.${cleanExt.toLowerCase()}')) {
    path = '$path.$cleanExt';
  }

  try {
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  } catch (e) {
    // Return null or rethrow? Usually better to return null and let the UI handle it or log it.
    debugPrint('Failed to save file: $e');
    return null;
  }
}
