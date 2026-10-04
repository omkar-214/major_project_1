import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProofService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pick(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );

    if (image == null) return null;

    Directory dir = await getApplicationDocumentsDirectory();
    Directory folder = Directory("${dir.path}/proofs");
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    String dest = "${folder.path}/proof_${DateTime.now().millisecondsSinceEpoch}.jpg";
    await File(image.path).copy(dest);
    return dest;
  }

  static Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;

    File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}