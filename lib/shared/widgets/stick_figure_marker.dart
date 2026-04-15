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
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDoppelganger ? const Color(0xFFFF2020) : const Color(0xFF00FF88);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: faceImage == null ? color : null,
        border: Border.all(color: color, width: 3),
        image: faceImage != null
            ? DecorationImage(
                image: FileImage(faceImage!),
                fit: BoxFit.cover,
                colorFilter: isDoppelganger
                    ? const ColorFilter.matrix([
                        0.4, 0, 0, 0, 60,
                        0, 0.05, 0, 0, 0,
                        0, 0, 0.05, 0, 0,
                        0, 0, 0, 0.9, 0,
                      ])
                    : null,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.7),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: faceImage == null
          ? Icon(
              isDoppelganger ? Icons.person : Icons.directions_run,
              color: Colors.white,
              size: size * 0.5,
            )
          : null,
    );
  }
}
