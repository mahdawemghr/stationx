import 'package:file_picker/file_picker.dart';

import 'gym_tracker_import.dart';

/// Result of asking the user for a file: its text, or null when they cancelled.
abstract class ImportFileSource {
  /// Throws [ImportException] (`tooLarge`) before reading a file bigger than [GymTrackerImport.maxBytes].
  Future<String?> pickJsonText();
}

/// System file picker (Storage Access Framework / document picker). The file is only read on this device.
class FilePickerImportSource implements ImportFileSource {
  const FilePickerImportSource();

  @override
  Future<String?> pickJsonText() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Choose your Gym Tracker export',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty) return null;
    final file = files.first;
    final size = await file.length();
    if (size != null && size > GymTrackerImport.maxBytes) {
      throw const ImportException(ImportProblem.tooLarge);
    }
    return file.xFile.readAsString();
  }
}
