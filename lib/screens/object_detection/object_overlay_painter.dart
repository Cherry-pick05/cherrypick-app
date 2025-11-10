import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectOverlayPainter extends CustomPainter {
  final List<DetectedObject> objects;
  // imageSize는 ML Kit이 처리한 '논리적' 크기 (예: 720x1280)
  final Size imageSize;

  ObjectOverlayPainter({
    required this.objects,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 'size'는 CustomPaint 위젯의 크기 (SizedBox 크기, 예: 360x550)
    // 'imageSize'는 ML Kit 논리적 크기 (예: 720x1280)

    // BoxFit.cover 스케일링 계산
    // 'size' (SizedBox)를 기준으로 다시 계산합니다.
    final double imageRatio = imageSize.width / imageSize.height;
    final double sizeRatio = size.width / size.height;

    double scale, dx = 0, dy = 0;

    if (imageRatio > sizeRatio) {
      // 높이를 'size'에 맞춤
      scale = size.height / imageSize.height;
      dx = (size.width - imageSize.width * scale) / 2;
    } else {
      // 너비를 'size'에 맞춤
      scale = size.width / imageSize.width;
      dy = (size.height - imageSize.height * scale) / 2;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.redAccent;

    for (var obj in objects) {
      // 스케일(scale)과 오프셋(dx, dy)을 모두 적용
      final Rect scaledRect = Rect.fromLTRB(
        obj.boundingBox.left * scale + dx,
        obj.boundingBox.top * scale + dy,
        obj.boundingBox.right * scale + dx,
        obj.boundingBox.bottom * scale + dy,
      );

      // 박스가 화면(size)을 벗어나지 않도록 제한
      final Rect clippedRect = scaledRect.intersect(Offset.zero & size);

      if (!clippedRect.isEmpty) {
        canvas.drawRect(clippedRect, paint);

        final String label = obj.labels.isNotEmpty
            ? "${obj.labels.first.text} (${(obj.labels.first.confidence * 100).toStringAsFixed(1)}%)"
            : "N/A";

        TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              backgroundColor: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )
          ..layout()
          ..paint(canvas, Offset(clippedRect.left + 5, clippedRect.top + 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant ObjectOverlayPainter oldDelegate) {
    // (수정) screenSize 비교 제거
    return oldDelegate.objects != objects ||
        oldDelegate.imageSize != imageSize;
  }
}