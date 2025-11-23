import 'package:flutter/material.dart';

class ObjectOverlayPainter extends CustomPainter {
  final List<Map<String, dynamic>> objects;
  final Size imageSize;

  ObjectOverlayPainter({
    required this.objects,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double imageRatio = imageSize.width / imageSize.height;
    final double sizeRatio = size.width / size.height;

    double scale, dx = 0, dy = 0;

    // 이미지 비율에 맞게 스케일링
    if (imageRatio > sizeRatio) {
      scale = size.height / imageSize.height;
      dx = (size.width - imageSize.width * scale) / 2;
    } else {
      scale = size.width / imageSize.width;
      dy = (size.height - imageSize.height * scale) / 2;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.redAccent;

    for (var obj in objects) {
      final bbox = obj['bbox'] as List<double>;
      final score = obj['score'] as double;
      
      // 클래스 이름 가져오기 (있으면 사용, 없으면 인덱스 사용)
      final className = obj['className'] as String?;
      final classIndex = obj['classIndex'] as int;
      final labelText = className ?? 'Object $classIndex';

      final Rect scaledRect = Rect.fromLTRB(
        bbox[0] * scale + dx,
        bbox[1] * scale + dy,
        bbox[2] * scale + dx,
        bbox[3] * scale + dy,
      );

      final Rect clippedRect = scaledRect.intersect(Offset.zero & size);

      if (!clippedRect.isEmpty) {
        // 바운딩 박스 그리기
        canvas.drawRect(clippedRect, paint);

        // 라벨 그리기
        final label = '$labelText ${(score * 100).toStringAsFixed(0)}%';
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black87,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        
        // 라벨 배경 그리기
        final labelRect = Rect.fromLTWH(
          clippedRect.left + 2,
          clippedRect.top - textPainter.height - 4,
          textPainter.width + 8,
          textPainter.height + 4,
        );
        final backgroundPaint = Paint()
          ..color = Colors.black.withOpacity(0.7)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
          backgroundPaint,
        );
        
        // 라벨 텍스트 그리기
        textPainter.paint(
          canvas,
          Offset(clippedRect.left + 6, clippedRect.top - textPainter.height - 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ObjectOverlayPainter oldDelegate) {
    return oldDelegate.objects != objects || oldDelegate.imageSize != imageSize;
  }
}

