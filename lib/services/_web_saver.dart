import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart';

/// Implémentation de [ImageSaverService] pour la plateforme web.
class WebImageSaver {
  Future<void> saveImage(Uint8List bytes, String fileName) async {
    // Crée un lien de téléchargement et le clique par programmation.
    final blob = Blob([bytes.toJS].toJS);

    final url = URL.createObjectURL(blob);
    final anchor = document.createElement('a') as HTMLAnchorElement
      ..href = url
      ..download = fileName;
    document.body!.append(anchor);
    anchor.click();    
    document.body!.removeChild(anchor);
    URL.revokeObjectURL(url);
  }
}