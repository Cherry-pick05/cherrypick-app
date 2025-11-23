import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

import 'tflite_detector.dart';
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
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  Size? _previewSize;

  TfliteDetector? _detector;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _detectedObjects = [];
  bool _isModelLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDetector();
    if (!kIsWeb) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      try {
        if (_cameraController?.value.isStreamingImages ?? false) {
          _cameraController?.stopImageStream();
        }
      } catch (e) {
        debugPrint('스트림 중지 오류: $e');
      }
      _cameraController?.dispose();
      _detector?.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeDetector() async {
    setState(() {
      _isModelLoading = true;
    });

    try {
      _detector = TfliteDetector();
      
      // 현재 사용 중인 모델 경로
      final modelPath = 'assets/best_float32.tflite';  // best_float32.tflite 사용
      
      await _detector!.initialize(modelPath: modelPath);
      
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
      debugPrint('✅ TFLite Detector 초기화 완료 (웹: $kIsWeb)');
    } catch (e, stackTrace) {
      debugPrint('❌ TFLite Detector 초기화 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      if (kIsWeb) {
        debugPrint('⚠️ 웹에서는 TFLite가 지원되지 않을 수 있습니다.');
        debugPrint('   웹에서는 TensorFlow.js를 사용해야 할 수 있습니다.');
      }
      
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
        // 웹에서는 취소하지 않고 이미지 선택만 허용
        if (!kIsWeb) {
          widget.onCancel();
        }
      }
    }
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint('❌ 카메라 권한 거부');
      widget.onCancel();
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('❌ 사용 가능한 카메라 없음');
        widget.onCancel();
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.low, // 성능 최적화: 낮은 해상도로 더 빠른 처리
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _previewSize = _cameraController!.value.previewSize;
      });

      _startImageStream();
      debugPrint('✅ 카메라 초기화 완료');
    } catch (e) {
      debugPrint('❌ 카메라 초기화 오류: $e');
      widget.onCancel();
    }
  }

  void _startImageStream() {
    DateTime? lastDetectionTime;
    int frameSkipCount = 0;
    const int framesToSkip = 1; // 2프레임마다 1번씩 처리 (약 66ms @ 30fps)

    _cameraController?.startImageStream((CameraImage cameraImage) async {
      if (_isProcessing || _detector == null || !_detector!.isInitialized) {
        return;
      }

      // 프레임 스킵 (성능 최적화)
      frameSkipCount++;
      if (frameSkipCount < framesToSkip) {
        return;
      }
      frameSkipCount = 0;

      // 최소 간격 체크 (200ms로 조정 - 반응성과 성능 균형)
      final now = DateTime.now();
      if (lastDetectionTime != null &&
          now.difference(lastDetectionTime!).inMilliseconds < 200) {
        return;
      }
      lastDetectionTime = now;

      _isProcessing = true;
      try {
        final detections = await _detector!.detectFromCameraImage(
          cameraImage,
          threshold: 0.25,
          maxDetections: 1, // 최고 신뢰도 객체 1개만 탐지
        );

        // 클래스 이름 추가 (빠른 매핑)
        final detectionsWithLabels = <Map<String, dynamic>>[];
        for (final det in detections) {
          final classIndex = det['classIndex'] as int;
          final className = _detector!.getTravelClassName(classIndex) ?? 'Unknown';
          detectionsWithLabels.add({
            ...det,
            'className': className,
          });
        }

        if (mounted) {
          setState(() {
            _detectedObjects = detectionsWithLabels;
          });
        }
      } catch (e) {
        debugPrint('❌ 탐지 오류: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라가 초기화되지 않았습니다.')),
      );
      return;
    }

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      final imageFile = await _cameraController!.takePicture();
      final imageBytes = await imageFile.readAsBytes();

      // 최종 탐지 수행
      List<String> labels = [];
      if (_detector != null && _detector!.isInitialized) {
        try {
          final detectedObjects = await _detector!.detectFromImageBytes(
            imageBytes,
            threshold: 0.25,
            maxDetections: 1, // 최고 신뢰도 객체 1개만 탐지
          );

          if (detectedObjects.isNotEmpty) {
            labels = detectedObjects
                .map((obj) {
                  final classIndex = obj['classIndex'] as int;
                  return _detector!.getTravelClassName(classIndex) ?? 'unknown';
                })
                .where((label) => label != 'unknown')
                .toSet()
                .toList();
          }
        } catch (e) {
          debugPrint('❌ 촬영 이미지 탐지 오류: $e');
        }
      }

      widget.onPhotoCaptured(imageBytes, labels);
    } catch (e) {
      debugPrint('❌ 사진 촬영 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 촬영 중 오류가 발생했습니다: $e')),
      );
    }
  }

  /// 웹에서 이미지 선택 및 탐지
  Future<void> _pickAndDetectImage() async {
    if (_detector == null || !_detector!.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모델이 초기화되지 않았습니다.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final imageBytes = await pickedFile.readAsBytes();

      // 이미지 표시를 위한 임시 저장
      setState(() {
        _selectedImageBytes = imageBytes;
      });

      // 객체 탐지 수행
      final detections = await _detector!.detectFromImageBytes(
        imageBytes,
        threshold: 0.25,
        maxDetections: 5,
      );

      // 클래스 이름 추가
      final detectionsWithLabels = detections.map((det) {
        final classIndex = det['classIndex'] as int;
        final className = _detector!.getTravelClassName(classIndex) ?? 'Unknown';
        return {
          ...det,
          'className': className,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _detectedObjects = detectionsWithLabels;
          _isProcessing = false;
        });
      }

      // 라벨 추출
      List<String> labels = detectionsWithLabels
          .map((obj) => obj['className'] as String)
          .where((label) => label != 'Unknown')
          .toSet()
          .toList();

      widget.onPhotoCaptured(imageBytes, labels);
    } catch (e) {
      debugPrint('❌ 웹 이미지 탐지 오류: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 탐지 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  /// 웹에서 갤러리에서 이미지 선택 및 탐지
  Future<void> _pickFromGallery() async {
    if (_detector == null || !_detector!.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모델이 초기화되지 않았습니다.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final imageBytes = await pickedFile.readAsBytes();

      // 이미지 표시를 위한 임시 저장
      setState(() {
        _selectedImageBytes = imageBytes;
      });

      // 객체 탐지 수행
      final detections = await _detector!.detectFromImageBytes(
        imageBytes,
        threshold: 0.25,
        maxDetections: 5,
      );

      // 클래스 이름 추가
      final detectionsWithLabels = detections.map((det) {
        final classIndex = det['classIndex'] as int;
        final className = _detector!.getTravelClassName(classIndex) ?? 'Unknown';
        return {
          ...det,
          'className': className,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _detectedObjects = detectionsWithLabels;
          _isProcessing = false;
        });
      }

      // 라벨 추출
      List<String> labels = detectionsWithLabels
          .map((obj) => obj['className'] as String)
          .where((label) => label != 'Unknown')
          .toSet()
          .toList();

      widget.onPhotoCaptured(imageBytes, labels);
    } catch (e) {
      debugPrint('❌ 웹 이미지 탐지 오류: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 탐지 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Uint8List? _selectedImageBytes; // 웹에서 선택한 이미지 저장

  @override
  Widget build(BuildContext context) {
    // 웹에서는 이미지 선택 방식 사용
    if (kIsWeb) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 선택한 이미지 미리보기
              if (_selectedImageBytes != null)
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 400,
                    maxWidth: double.infinity,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '이미지를 선택하세요',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              
              // 감지된 객체 표시
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
                          '감지된 아이템: ${_detectedObjects.map((obj) => obj['className'] ?? 'Unknown').where((name) => name != 'Unknown').toSet().join(", ")}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // 모델 로딩 상태
              if (_isModelLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('모델 로딩 중...'),
                    ],
                  ),
                ),
              
              // 버튼
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_detector != null && 
                                  _detector!.isInitialized && 
                                  !_isProcessing)
                          ? _pickAndDetectImage
                          : null,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('카메라로 촬영'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_detector != null && 
                                  _detector!.isInitialized && 
                                  !_isProcessing)
                          ? _pickFromGallery
                          : null,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('갤러리에서 선택'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close),
                label: const Text('취소'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 카메라 프리뷰
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _isCameraInitialized && _cameraController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController!),
                          if (_previewSize != null && _detectedObjects.isNotEmpty)
                            CustomPaint(
                              painter: ObjectOverlayPainter(
                                objects: _detectedObjects,
                                imageSize: _previewSize!,
                              ),
                            ),
                        ],
                      ),
                    )
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: _isModelLoading
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                    '모델 로딩 중...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )
                            : const CircularProgressIndicator(),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // 감지된 라벨 표시
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
                        '감지된 아이템: ${_detectedObjects.map((obj) => obj['className'] ?? 'Unknown').where((name) => name != 'Unknown').toSet().join(", ")}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_detector != null && _detector!.isInitialized)
                        ? _capturePhoto
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
}

