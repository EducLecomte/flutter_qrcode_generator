import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_qrcode_generator/services/_web_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Generator',
      theme: ThemeData(
        brightness: Brightness.light, // ou Brightness.dark selon le thème souhaité
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const QRCodeGeneratorPage(),
    );
  }
}

class QRCodeGeneratorPage extends StatefulWidget {
  const QRCodeGeneratorPage({super.key});

  @override
  State<QRCodeGeneratorPage> createState() => _QRCodeGeneratorPageState();
}

class _QRCodeGeneratorPageState extends State<QRCodeGeneratorPage> {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  final WebImageSaver _imageSaver = WebImageSaver();

  bool _isSaving = false;
  String _qrData = "Générateur de QR Code"; // Texte initial pour le QR code

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _qrData = _textController.text.isEmpty
          ? "Générateur de QR Code"
          : _textController.text;
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  /// Capture le widget du QR code en tant qu'image et la sauvegarde.
  Future<void> _captureAndSavePng() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Impossible de convertir l\'image.');

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final String fileName =
          "qr_code_${DateTime.now().millisecondsSinceEpoch}.png";

      await _imageSaver.saveImage(pngBytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Téléchargement du QR Code initié.')));
      }
    } catch (e, stackTrace) {      
      debugPrint('Erreur lors de la sauvegarde: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Une erreur est survenue lors de la sauvegarde.'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Générateur de QR Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _QrCodeInput(textController: _textController),
            const SizedBox(height: 20),
            Expanded(
              child: _QrCodeView(qrKey: _qrKey, qrData: _qrData),
            ),
            const SizedBox(height: 20),
            _SaveButton(
              isSaving: _isSaving,
              onPressed: _captureAndSavePng,
            )
          ],
        ),
      ),
    );
  }
}

/// Widget affichant le champ de saisie de texte.
class _QrCodeInput extends StatelessWidget {
  const _QrCodeInput({required this.textController});

  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Saisissez le texte pour le QR Code',
        hintText: 'Ex: https://flutter.dev',
      ),
    );
  }
}

/// Widget qui affiche le QR Code dans un RepaintBoundary.
class _QrCodeView extends StatelessWidget {
  const _QrCodeView({
    required this.qrKey,
    required this.qrData,
  });

  final GlobalKey qrKey;
  final String qrData;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RepaintBoundary(
        key: qrKey,
        child: QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 280.0,
          gapless: false,
          backgroundColor: Colors.white,
          dataModuleStyle: QrDataModuleStyle(
            color: Theme.of(context).colorScheme.onSurface,
            dataModuleShape: QrDataModuleShape.square,
          ),
          eyeStyle: QrEyeStyle(
            color: Theme.of(context).colorScheme.onSurface,
            eyeShape: QrEyeShape.square,
          ),
        ),
      ),
    );
  }
}

/// Widget pour le bouton de sauvegarde qui affiche un indicateur de chargement.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isSaving ? null : onPressed,
      icon: isSaving ? const SizedBox.shrink() : const Icon(Icons.save_alt),
      label: isSaving ? const CircularProgressIndicator() : const Text("Télécharger (.png)"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}
