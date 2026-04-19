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

    // 프로필 사진이 없을 때는 지도 표준 "위치 점" 스타일 (채워진 작은 원 + 흰 테두리 + 약한 글로우).
    // 전체 컨테이너는 투명하게 두고 중앙에만 작은 마커를 그린다.
    if (faceImage == null) {
      final dotSize = isDoppelganger ? 24.0 : 26.0;
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 프로필 사진이 있을 때 — 지도 표준 크기로 축소. 사진 + 컬러 테두리 + 약한 글로우.
    // 과거 64/56 은 지도를 가릴 정도로 컸음.
    final faceSize = isDoppelganger ? 32.0 : 36.0;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Container(
          width: faceSize,
          height: faceSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            image: DecorationImage(
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
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
