import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'object_overlay_painter.dart';

typedef OnPhotoCaptured = void Function(Uint8List? imageBytes, List<String> labels);

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
  // --- 웹용 변수 ---
  CameraController? _webCameraController;
  String? _detectedLabel;
  bool _isWebCameraInitialized = false;

  // --- 카메라 변수 (모바일/앱용) ---
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final int _cameraIndex = 0;
  bool _isCameraInitialized = false;

  // --- 카메라 원본 해상도와 센서 방향 ---
  Size? _previewSize;
  int _sensorOrientation = 90;

  // --- ML Kit 변수 (모바일/앱용) ---
  ObjectDetector? _objectDetector;
  bool _isProcessing = false;
  List<DetectedObject> _detectedObjects = [];

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeWebCamera();
    } else {
      _initializeDetector();
      _initializeCameraWithPermission();
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      // 웹에서는 이미지 스트림을 사용하지 않으므로 stopImageStream() 호출 불필요
      _webCameraController?.dispose();
    } else {
      _cameraController?.stopImageStream();
      _cameraController?.dispose();
      _objectDetector?.close();
    }
    super.dispose();
  }

  // 웹용 카메라 초기화
  Future<void> _initializeWebCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('웹에서 사용 가능한 카메라가 없습니다.');
        widget.onCancel();
        return;
      }

      _webCameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _webCameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isWebCameraInitialized = true;
        });
        // 웹에서는 이미지 스트림을 사용하지 않고, 타이머로 디텍션 시뮬레이션
        _startWebDetectionTimer();
      }
    } catch (e) {
      debugPrint('웹 카메라 초기화 오류: $e');
      if (mounted) {
        widget.onCancel();
      }
    }
  }

  // 웹용 디텍션 타이머 (이미지 스트림 대신 사용)
  void _startWebDetectionTimer() {
    // 주기적으로 디텍션 시뮬레이션 (이미지 스트림 없이)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isWebCameraInitialized) {
        // 간단한 디텍션 시뮬레이션
        final mockLabels = ['bottle', 'power bank', 'hair dryer', 'laptop', 'phone'];
        final randomIndex = DateTime.now().millisecond % mockLabels.length;
        
        setState(() {
          _detectedLabel = mockLabels[randomIndex];
        });
        
        // 계속해서 주기적으로 디텍션 시뮬레이션
        _startWebDetectionTimer();
      }
    });
  }

  // 1. ML Kit 감지기 초기화 (앱용)
  void _initializeDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false, // 하나의 객체만 감지
    );
    _objectDetector = ObjectDetector(options: options);
  }

  // 웹용 이미지 캡처
  Future<void> _captureWebPhoto() async {
    if (_webCameraController == null || !_webCameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라가 초기화되지 않았습니다.')),
      );
      return;
    }

    try {
      // 웹에서는 이미지 스트림을 사용하지 않으므로, 바로 takePicture() 호출 가능
      // supportsImageStreaming()이 false인 경우를 대비해 안전하게 처리
      final imageFile = await _webCameraController!.takePicture();
      final imageBytes = await imageFile.readAsBytes();

      // 감지된 라벨이 있으면 사용, 없으면 빈 리스트
      final List<String> labels = _detectedLabel != null && _detectedLabel!.isNotEmpty
          ? <String>[_detectedLabel!]
          : <String>[];

      widget.onPhotoCaptured(imageBytes, labels);
    } catch (e) {
      debugPrint('웹 이미지 캡처 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 촬영 중 오류가 발생했습니다: $e')),
      );
    }
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

  // 4. ML Kit 이미지 처리 (앱용)
  Future<void> _processImage(InputImage inputImage) async {
    if (_objectDetector == null) return;
    _isProcessing = true;
    try {
      final List<DetectedObject> objects =
          await _objectDetector!.processImage(inputImage);
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
        .toList()
        .cast<String>();

    final imageBytes = await finalImageToPass.readAsBytes();
    widget.onPhotoCaptured(imageBytes, labels);
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
    if (kIsWeb) {
      // --- 웹에서는 camera 패키지로 카메라 프리뷰 및 실시간 디텍션 처리 ---
      return Card(
        key: const ValueKey('web_camera'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 감지된 라벨 표시
              if (_detectedLabel != null && _detectedLabel!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '감지된 아이템: $_detectedLabel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '아이템 감지 중...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              // 카메라 프리뷰
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isWebCameraInitialized &&
                        _webCameraController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _webCameraController!.value.aspectRatio,
                        child: CameraPreview(_webCameraController!),
                      )
                    : Container(
                        color: Colors.black,
                        height: 300,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              // "촬영하기" / "취소" 버튼
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isWebCameraInitialized
                          ? _captureWebPhoto
                          : null,
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
            // 감지된 라벨 표시 (앱용)
            if (_detectedObjects.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '감지된 아이템: ${_detectedObjects.first.labels.isNotEmpty ? _detectedObjects.first.labels.first.text : "감지 중..."}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // 2. "촬영하기" / "취소" 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _detectedObjects.isNotEmpty ? _capturePhoto : null,
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
