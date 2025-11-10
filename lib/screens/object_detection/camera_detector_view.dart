import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:permission_handler/permission_handler.dart';
// object_overlay_painter.dart는 같은 폴더에 있으므로 경로 수정
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
  int _cameraIndex = 0;
  bool _isCameraInitialized = false;

  // --- 카메라 원본 해상도와 센서 방향 ---
  Size? _previewSize; // 카메라 프리뷰의 원본 해상도 (예: 1280x720)
  int _sensorOrientation = 90; // 센서 방향 (기본값 90)

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
      multipleObjects: true,
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
    final List<DetectedObject> objects =
    await _objectDetector.processImage(inputImage);
    if (mounted) {
      setState(() {
        _detectedObjects = objects;
      });
    }
    _isProcessing = false;
  }

  // 5. "촬영하기" 버튼 로직
  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    await _cameraController?.stopImageStream();
    _isProcessing = false;
    final image = await _cameraController!.takePicture();
    final List<String> labels = _detectedObjects
        .map((obj) => obj.labels.isNotEmpty ? obj.labels.first.text : "")
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();
    widget.onPhotoCaptured(image, labels);
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
      rotation = InputImageRotationValue.fromRawValue(
          (sensorOrientation + 360) % 360) ??
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
              child: SizedBox(
                height: 550,
                width: double.infinity,
                child: !_isCameraInitialized || _previewSize == null
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_cameraController!),
                    Builder(
                        builder: (context) {
                          // 센서 방향 확인
                          final isRotated = _sensorOrientation == 90 || _sensorOrientation == 270;
                          // ML Kit이 보는 논리적 크기 계산
                          final logicalSize = isRotated
                              ? Size(_previewSize!.height, _previewSize!.width)
                              : _previewSize!;

                          return CustomPaint(
                            painter: ObjectOverlayPainter(
                              objects: _detectedObjects,
                              imageSize: logicalSize, // 논리적 크기 전달
                            ),
                          );
                        }
                    ),
                    if (kIsWeb)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '브라우저 권한 팝업을 허용하세요',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
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