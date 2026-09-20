import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Helper to generate sample certified endorsement scan images for test & demo.
class SampleEndorsementGenerator {
  static Future<Uint8List> generateStampImage({
    required String title,
    required String regulator,
    required String details,
    required DateTime date,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 600, 380));

    // Document Paper Background
    final bgPaint = Paint()..color = const Color(0xFFFBF9F1);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 600, 380), bgPaint);

    // Document Border
    final borderPaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(16, 16, 568, 348), const Radius.circular(8)),
      borderPaint,
    );

    // Inner Stamp Border
    final innerBorder = Paint()
      ..color = const Color(0xFF1E3A8A).withAlpha(120)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(24, 24, 552, 332), const Radius.circular(6)),
      innerBorder,
    );

    // Header Text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: '$regulator OFFICIAL ENDORSEMENT',
      style: const TextStyle(
        color: Color(0xFF1E3A8A),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(40, 45));

    // Rating Title
    textPainter.text = TextSpan(
      text: title,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(40, 85));

    // Details Body
    textPainter.text = TextSpan(
      text:
          'This certifies that the holder has completed the required syllabus\nand has demonstrated proficiency in accordance with regulations:\n\n$details',
      style: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 14,
        height: 1.4,
      ),
    );
    textPainter.layout(maxWidth: 520);
    textPainter.paint(canvas, const Offset(40, 130));

    // Certification line
    textPainter.text = TextSpan(
      text: 'DATE: ${date.day}/${date.month}/${date.year}     CFI / EXAMINER: Capt. J. Miller (Lic #642918)\nSIGNATURE: __________________________   SEAL: [VERIFIED]',
      style: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 12,
        fontStyle: FontStyle.italic,
      ),
    );
    textPainter.layout(maxWidth: 520);
    textPainter.paint(canvas, const Offset(40, 265));

    // Stamp circle
    final stampPaint = Paint()
      ..color = const Color(0xFFB91C1C).withAlpha(180)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(490, 280), 38, stampPaint);

    textPainter.text = const TextSpan(
      text: 'OFFICIAL\nSTAMP\nVALID',
      style: TextStyle(
        color: Color(0xFFB91C1C),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(465, 260));

    final picture = recorder.endRecording();
    final img = await picture.toImage(600, 380);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

