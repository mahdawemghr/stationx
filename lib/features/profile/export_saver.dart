import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Saves an export file. Returns true when saved, false when the user cancelled;
/// throws when the platform cannot save (caller falls back to the clipboard).
typedef ExportSaver = Future<bool> Function(String fileName, String text);

Future<bool> saveExportWithFilePicker(String fileName, String text) async {
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: Uint8List.fromList(utf8.encode(text)),
    dialogTitle: 'Save your StationX export',
  );
  return uri != null;
}
