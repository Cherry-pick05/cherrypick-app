import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'object_overlay_painter.dart';

typedef OnPhotoCaptured = void Function(XFile image, List<String> labels);

class CameraDetectorView extends StatefulWidget {
  final OnPhotoCaptured onPhotoCaptured;
  final VoidCallback onCancel;

  const CameraDetectorView({
    super.key,
    required this.onPhotoCaptured,
    required this.onCancel,
  });

  @override
  State<CameraDetectorView> createState() => _CameraDetectorViewState();
}

class _CameraDetectorViewState extends State<CameraDetectorView> {
  // --- 카메라 변수 ---
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final int _cameraIndex = 0;
  bool _isCameraInitialized = false;

  // --- 카메라 원본 해상도와 센서 방향 ---
  Size? _previewSize;
  int _sensorOrientation = 90;

  // --- ML Kit 변수 ---
  late ObjectDetector _objectDetector;
  bool _isProcessing = false;
  List<DetectedObject> _detectedObjects = [];

  @override
  void initState() {
    super.initState();
    _initializeDetector();
    _initializeCameraWithPermission();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _objectDetector.close();
    super.dispose();
  }

  // 1. ML Kit 감지기 초기화
  void _initializeDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false, // 하나의 객체만 감지
    );
    _objectDetector = ObjectDetector(options: options);
  }

  // 2. 권한 요청 및 카메라 초기화
  Future<void> _initializeCameraWithPermission() async {
    if (await Permission.camera.request().isGranted) {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![_cameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.nv21,
        );
        await _cameraController!.initialize();

        _previewSize = _cameraController!.value.previewSize;
        _sensorOrientation = _cameraController!.description.sensorOrientation;

        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
        _startImageStream();
      }
    } else {
      debugPrint('카메라 권한이 거부되었습니다.');
      widget.onCancel();
    }
  }

  // 3. 실시간 이미지 스트림 처리 시작
  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage cameraImage) {
      if (_isProcessing) return;
      final inputImage = _inputImageFromCameraImage(cameraImage);
      if (inputImage == null) return;
      _processImage(inputImage);
    });
  }

  // 4. ML Kit 이미지 처리
  Future<void> _processImage(InputImage inputImage) async {
    _isProcessing = true;
    try {
      final List<DetectedObject> objects =
          await _objectDetector.processImage(inputImage);
      if (mounted) {
        setState(() {
          _detectedObjects = objects;
        });
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    }
    _isProcessing = false;
  }

  // 5. "촬영하기" 버튼 로직 (좌표 변환 로직 전면 수정)
  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _previewSize == null) {
      return;
    }

    await _cameraController?.stopImageStream();
    _isProcessing = false;

    final imageFile = await _cameraController!.takePicture();
    final detectedObject = _detectedObjects.firstOrNull;

    XFile finalImageToPass = imageFile;

    if (detectedObject != null) {
      try {
        final imageBytes = await imageFile.readAsBytes();
        final img.Image? originalImage = img.decodeImage(imageBytes);

        if (originalImage != null) {
          final Rect boundingBox = detectedObject.boundingBox;

          final double imageWidth = originalImage.width.toDouble();
          final double imageHeight = originalImage.height.toDouble();

          final double previewWidth = _previewSize!.width;
          final double previewHeight = _previewSize!.height;

          final double imageAspectRatio = imageWidth / imageHeight;
          final double previewAspectRatio = previewWidth / previewHeight;

          double scale;
          double offsetX = 0;
          double offsetY = 0;

          if (previewAspectRatio > imageAspectRatio) {
            scale = previewWidth / imageWidth;
            final scaledImageHeight = imageHeight * scale;
            offsetY = (scaledImageHeight - previewHeight) / 2.0;
          } else {
            scale = previewHeight / imageHeight;
            final scaledImageWidth = imageWidth * scale;
            offsetX = (scaledImageWidth - previewWidth) / 2.0;
          }

          final double imgLeft = (boundingBox.left + offsetX) / scale;
          final double imgTop = (boundingBox.top + offsetY) / scale;
          final double imgWidth = boundingBox.width / scale;
          final double imgHeight = boundingBox.height / scale;

          final double boxCenterX = imgLeft + imgWidth / 2.0;
          final double boxCenterY = imgTop + imgHeight / 2.0;
          final double longSide = max(imgWidth, imgHeight);
          final double squareSize = longSide * 1.2; 

          int finalCropSize = squareSize.round();

          finalCropSize =
              min(finalCropSize, min(imageWidth.round(), imageHeight.round()));

          int finalCropX = (boxCenterX - finalCropSize / 2.0)
              .round()
              .clamp(0, imageWidth.round() - finalCropSize);
          int finalCropY = (boxCenterY - finalCropSize / 2.0)
              .round()
              .clamp(0, imageHeight.round() - finalCropSize);

          final img.Image croppedImage = img.copyCrop(
            originalImage,
            x: finalCropX,
            y: finalCropY,
            width: finalCropSize,
            height: finalCropSize,
          );

          final croppedBytes = img.encodeJpg(croppedImage);
          final tempDir = await getTemporaryDirectory();
          final filePath =
              '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final newFile = await File(filePath).writeAsBytes(croppedBytes);

          finalImageToPass = XFile(newFile.path);
        }
      } catch (e) {
        debugPrint("이미지 자르기 오류: $e");
      }
    }

    final List<String> labels = _detectedObjects
        .map((obj) => obj.labels.isNotEmpty ? obj.labels.first.text : "")
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();

    widget.onPhotoCaptured(finalImageToPass, labels);
  }

  // 6. CameraImage -> InputImage 변환
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation rotation;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;
    } else {
      rotation =
          InputImageRotationValue.fromRawValue((sensorOrientation + 360) % 360) ??
              InputImageRotation.rotation0deg;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format != InputImageFormat.nv21) {
      debugPrint("지원하지 않는 이미지 포맷: ${image.format.raw}");
      return null;
    }

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  // --- UI 빌드 메소드 ---
  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('camera'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. 카메라 뷰 + 오버레이
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _isCameraInitialized &&
                      _cameraController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController!),
                          Builder(builder: (context) {
                            final isRotated = _sensorOrientation == 90 ||
                                _sensorOrientation == 270;
                            final logicalSize = isRotated
                                ? Size(_previewSize!.height, _previewSize!.width)
                                : _previewSize!;

                            return CustomPaint(
                              painter: ObjectOverlayPainter(
                                objects: _detectedObjects,
                                imageSize: logicalSize,
                              ),
                            );
                          }),
                        ],
                      ),
                    )
                  : Container(
                      color: Colors.black,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
            ),
            const SizedBox(height: 16),
            // 2. "촬영하기" / "취소" 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _capturePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('촬영하기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                    label: const Text('취소'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
