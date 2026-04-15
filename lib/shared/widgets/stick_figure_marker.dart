import 'dart:io';
import 'package:flutter/material.dart';

class StickFigureMarker extends StatelessWidget {
  final File? faceImage;
  final bool isDoppelganger;
  final double size;

  const StickFigureMarker({
    super.key,
    this.faceImage,
    this.isDoppelganger = false,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDoppelganger ? const Color(0xFFFF2020) : const Color(0xFF00FF88);
    final headSize = size * 0.35;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StickFigurePainter(
          color: color,
          isDoppelganger: isDoppelganger,
        ),
        child: Align(
          alignment: const Alignment(0, -0.65),
          child: _buildHead(headSize),
        ),
      ),
    );
  }

  Widget _buildHead(double headSize) {
    if (faceImage != null) {
      return Container(
        width: headSize,
        height: headSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDoppelganger ? const Color(0xFFFF2020) : const Color(0xFF00FF88),
            width: 1.5,
          ),
          image: DecorationImage(
            image: FileImage(faceImage!),
            fit: BoxFit.cover,
            colorFilter: isDoppelganger
                ? const ColorFilter.matrix([
                    0.5, 0, 0, 0, 50,
                    0, 0.1, 0, 0, 0,
                    0, 0, 0.1, 0, 0,
                    0, 0, 0, 0.8, 0,
                  ])
                : null,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDoppelganger ? const Color(0xFFFF2020) : const Color(0xFF00FF88))
                  .withValues(alpha: 0.5),
              blurRadius: 6,
            ),
          ],
        ),
      );
    }

    // No face image - simple circle head
    return Container(
      width: headSize,
      height: headSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDoppelganger ? const Color(0xFFFF2020) : const Color(0xFF00FF88),
        boxShadow: [
          BoxShadow(
            color: (isDoppelganger ? const Color(0xFFFF2020) : const Color(0xFF00FF88))
                .withValues(alpha: 0.5),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _StickFigurePainter extends CustomPainter {
  final Color color;
  final bool isDoppelganger;

  _StickFigurePainter({required this.color, required this.isDoppelganger});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final headRadius = size.width * 0.175;
    final neckY = size.height * 0.17 + headRadius * 2;
    final bodyEndY = size.height * 0.6;

    // Body (torso) - slight lean forward for running
    canvas.drawLine(
      Offset(cx, neckY),
      Offset(cx - 2, bodyEndY),
      paint,
    );

    // Left arm - back swing
    canvas.drawLine(
      Offset(cx, neckY + 4),
      Offset(cx + size.width * 0.22, bodyEndY - 8),
      paint,
    );

    // Right arm - forward swing
    canvas.drawLine(
      Offset(cx, neckY + 4),
      Offset(cx - size.width * 0.25, neckY + 12),
      paint,
    );

    // Left leg - forward stride
    canvas.drawLine(
      Offset(cx - 2, bodyEndY),
      Offset(cx - size.width * 0.2, size.height * 0.85),
      paint,
    );
    // Left foot
    canvas.drawLine(
      Offset(cx - size.width * 0.2, size.height * 0.85),
      Offset(cx - size.width * 0.28, size.height * 0.95),
      paint,
    );

    // Right leg - back stride
    canvas.drawLine(
      Offset(cx - 2, bodyEndY),
      Offset(cx + size.width * 0.18, size.height * 0.9),
      paint,
    );
    // Right foot
    canvas.drawLine(
      Offset(cx + size.width * 0.18, size.height * 0.9),
      Offset(cx + size.width * 0.1, size.height * 0.98),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
