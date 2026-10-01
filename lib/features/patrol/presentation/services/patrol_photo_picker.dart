import 'package:image_picker/image_picker.dart';

import '../../domain/models/patrol_models.dart';

enum PatrolPhotoSource { camera, gallery }

enum PatrolPhotoSelectionFailureCode {
  unsupportedType,
  tooLarge,
  unavailable,
}

class PatrolPhotoSelectionException implements Exception {
  const PatrolPhotoSelectionException(this.code, {this.message});

  final PatrolPhotoSelectionFailureCode code;
  final String? message;
}

abstract interface class PatrolPhotoPicker {
  Future<PatrolPhotoInput?> pick(PatrolPhotoSource source);
}

class ImagePickerPatrolPhotoPicker implements PatrolPhotoPicker {
  ImagePickerPatrolPhotoPicker({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<PatrolPhotoInput?> pick(PatrolPhotoSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source == PatrolPhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (file == null) return null;

      final size = await file.length();
      if (size <= 0 || size > PatrolPhotoInput.maxFileSizeBytes) {
        throw const PatrolPhotoSelectionException(
          PatrolPhotoSelectionFailureCode.tooLarge,
        );
      }

      final mimeType = _resolveMimeType(file.mimeType, file.name);
      if (mimeType == null ||
          !PatrolPhotoInput.allowedMimeTypes.contains(mimeType)) {
        throw const PatrolPhotoSelectionException(
          PatrolPhotoSelectionFailureCode.unsupportedType,
        );
      }

      return PatrolPhotoInput(
        path: file.path,
        originalName: file.name,
        mimeType: mimeType,
        fileSize: size,
      );
    } on PatrolPhotoSelectionException {
      rethrow;
    } on Object catch (error) {
      throw PatrolPhotoSelectionException(
        PatrolPhotoSelectionFailureCode.unavailable,
        message: error.toString(),
      );
    }
  }

  static String? _resolveMimeType(String? supplied, String fileName) {
    final normalized = supplied?.trim().toLowerCase();
    if (normalized != null && normalized.isNotEmpty) return normalized;

    final name = fileName.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return null;
  }
}
