import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../domain/models.dart';

class CoverImages {
  static const maxBytes = 256 * 1024;
  static const maxDimension = 1280;
  static const channel = MethodChannel('de.anurag.guided_notes/images');

  static Future<Uint8List?> pick() async {
    final bytes = await channel.invokeMethod<Uint8List>('pick');
    if (bytes != null) await validate(bytes);
    return bytes;
  }

  /// Decode only after checking byte size and encoded dimensions.
  static Future<void> validate(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const RuleViolation('Das Bild darf höchstens 256 KB groß sein.');
    }
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        try {
          if (descriptor.width > maxDimension ||
              descriptor.height > maxDimension) {
            throw const FormatException('dimensions');
          }
          final codec = await descriptor.instantiateCodec();
          try {
            if (codec.frameCount != 1) throw const FormatException('animated');
            final frame = await codec.getNextFrame();
            frame.image.dispose();
          } finally {
            codec.dispose();
          }
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
    } catch (_) {
      throw const RuleViolation(
        'Das Hintergrundbild ist ungültig oder zu groß. Bitte ein anderes Bild wählen.',
      );
    }
  }
}
