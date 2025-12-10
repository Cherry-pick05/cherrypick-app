/// ============================================================
/// 물품 스캔 위젯 (ItemScanner)
/// ============================================================
/// 
/// 기능:
/// 1. 카메라를 통한 실시간 물품 촬영
/// 2. YOLO AI 모델을 사용한 실시간 객체 탐지 (toothpaste, bottle 등)
/// 3. 갤러리에서 사진 업로드
/// 4. 스캔 결과를 Preview API로 전송하여 상세 규정 조회
/// 5. ItemPreviewScreen으로 이동하여 규정 정보 표시
/// 
/// 주요 흐름:
/// - 카메라 시작 → 실시간 탐지 (0.5초마다) → 객체 선택 → 촬영 → 
///   스캔 결과 생성 → Preview API 호출 → ItemPreviewScreen 이동

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
// 🔹 ultralytics_yolo 패키지 import
// 참고: 패키지 설치 후 실제 API에 맞게 수정 필요
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../providers/trip_provider.dart';

// 🔹 Preview API 관련
import '../providers/preview_provider.dart';
import '../models/preview_request.dart';
import '../screens/item_preview_screen.dart';

/// 물품 스캔 화면 위젯
/// 카메라 촬영 또는 갤러리 업로드를 통해 물품을 스캔하고 AI로 분석합니다.
class ItemScanner extends StatefulWidget {
  const ItemScanner({super.key});

  @override
  State<ItemScanner> createState() => _ItemScannerState();
}

class _ItemScannerState extends State<ItemScanner> {
  // ============================================================
  // 상태 변수들
  // ============================================================
  
  /// 카메라 컨트롤러: 카메라 프리뷰와 촬영을 제어
  CameraController? _cameraController;
  
  /// 사용 가능한 카메라 목록
  List<CameraDescription>? _cameras;
  
  /// 카메라가 현재 활성화되어 있는지 여부
  bool _isCameraActive = false;
  
  /// 스캔 중인지 여부 (AI 분석 중 표시용)
  bool _isScanning = false;
  
  /// Preview API 호출 중인지 여부
  bool _isPreviewLoading = false;

  /// 선택된 이미지 파일 (카메라 촬영 또는 갤러리에서 선택)
  XFile? _selectedImage;
  
  /// 스캔 결과 데이터 (아이템 이름, 카테고리, 규정 등)
  ScanResult? _scanResult;

  // ============================================================
  // YOLO AI 모델 관련 변수
  // ============================================================
  
  /// YOLO 객체 탐지 모델 인스턴스
  YOLO? _yoloModel;
  
  /// 모델이 로딩 중인지 여부
  bool _isModelLoading = false;
  
  /// 모델이 초기화 완료되었는지 여부
  bool _isModelInitialized = false;
  
  /// 실시간으로 탐지된 객체들의 목록 (바운딩박스, 라벨, 컨피던스 포함)
  List<DetectionResult> _detectionResults = [];
  
  /// 실시간 탐지를 위한 타이머 (0.5초마다 프레임 처리)
  Timer? _detectionTimer;
  
  /// 사용자가 선택한 탐지 객체의 라벨 (여러 객체가 탐지되었을 때 선택)
  String? _selectedDetectionLabel;

  @override
  void initState() {
    super.initState();
    // 위젯이 생성될 때 카메라와 YOLO 모델을 초기화
    _initializeCamera();
    _initializeYOLOModel();
  }

  /// ============================================================
  /// 카메라 초기화
  /// ============================================================
  /// 사용 가능한 카메라를 찾고 첫 번째 카메라로 컨트롤러를 초기화합니다.
  /// 웹과 모바일 모두에서 동작합니다.
  Future<void> _initializeCamera() async {
    try {
      // 사용 가능한 모든 카메라 목록 가져오기
      _cameras = await availableCameras(); // 웹/모바일 공통
      
      if (_cameras != null && _cameras!.isNotEmpty) {
        // 첫 번째 카메라로 컨트롤러 생성 (고해상도 설정)
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.high, // 고해상도로 설정하여 탐지 정확도 향상
          enableAudio: false, // 오디오는 필요 없음
        );
        
        // 카메라 초기화 완료 대기
        await _cameraController!.initialize();
        
        // 위젯이 아직 마운트되어 있는지 확인 (메모리 누수 방지)
        if (!mounted) return;
        
        // UI 업데이트
        setState(() {});
      }
    } catch (e) {
      debugPrint('카메라 초기화 실패: $e');
      // 웹에서 권한 거부, 디바이스 없음 등 다양한 경우가 있으므로 UI는 계속 표시
      // 에러가 발생해도 앱이 크래시되지 않도록 처리
    }
  }

  /// ============================================================
  /// YOLO AI 모델 초기화
  /// ============================================================
  /// YOLO-World 모델을 로드하여 실시간 객체 탐지를 준비합니다.
  /// 모델은 assets/models/yolov8s-worldv2.pt 파일에서 로드됩니다.
  Future<void> _initializeYOLOModel() async {
    // 이미 로딩 중이거나 초기화 완료되었으면 중복 실행 방지
    if (_isModelLoading || _isModelInitialized) return;

    setState(() {
      _isModelLoading = true;
    });

    try {
      // 탐지할 수 있는 물품 클래스 목록 (YOLO-World 모델이 인식 가능한 항목들)
      // 참고: 실제 모델 파일에 이 클래스들이 포함되어 있어야 합니다
      final customClasses = [
        "toothpaste",    // 치약
        "toothbrush",    // 칫솔
        "clothes",       // 옷
        "fan",           // 선풍기
        "battery",       // 배터리
        "person",        // 사람
        "bottle",        // 병
        "glasses",       // 안경
        "cell phone",    // 휴대폰
        "power bank",    // 보조배터리
        "cosmetics",     // 화장품
      ];

      // YOLO 모델 인스턴스 생성
      // modelPath: pubspec.yaml의 assets에 등록된 경로 사용
      _yoloModel = YOLO(
        modelPath: 'assets/models/yolov8s-worldv2.pt', // 모델 파일 경로
        task: YOLOTask.detect, // 객체 탐지 작업
        useGpu: true, // GPU 가속 사용 (성능 향상)
      );

      // 모델 파일을 메모리에 로드
      final success = await _yoloModel!.loadModel();

      if (!mounted) return;

      if (success) {
        // 모델 로드 성공
        setState(() {
          _isModelInitialized = true;
          _isModelLoading = false;
        });
        debugPrint('YOLO 모델 초기화 완료');
        debugPrint('탐지할 클래스: $customClasses');
        // 참고: YOLO-World의 커스텀 클래스 설정은 모델 자체에 포함되어 있을 수 있습니다
        // 이 패키지에서 직접 setClasses를 지원하지 않을 수 있으므로 모델 파일에 클래스가 포함되어 있어야 합니다
      } else {
        // 모델 로드 실패
        setState(() {
          _isModelLoading = false;
        });
        debugPrint('YOLO 모델 로드 실패');
      }
    } catch (e) {
      debugPrint('YOLO 모델 초기화 실패: $e');
      if (!mounted) return;
      setState(() {
        _isModelLoading = false;
      });
      // 모델 로딩 실패해도 UI는 계속 표시 (사용자가 갤러리 업로드는 가능)
    }
  }

  /// ============================================================
  /// 실시간 프레임 처리 및 객체 탐지
  /// ============================================================
  /// 카메라에서 현재 프레임을 캡처하고 YOLO 모델로 객체를 탐지합니다.
  /// 0.5초마다 이 함수가 호출됩니다 (_startDetection에서 타이머 설정).
  Future<void> _processFrame() async {
    // 모든 필수 조건이 충족되었는지 확인
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _yoloModel == null ||
        !_isModelInitialized ||
        !_isCameraActive) {
      return; // 조건 불충족 시 탐지 중단
    }

    try {
      // 1. 카메라에서 현재 프레임을 이미지로 캡처
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      // 2. YOLO 모델로 객체 탐지 수행
      final results = await _yoloModel!.predict(
        imageBytes,
        confidenceThreshold: 0.3, // 30% 이상 컨피던스만 표시 (낮은 신뢰도 결과 제외)
        iouThreshold: 0.4, // 겹치는 박스 제거 임계값
      );

      // 3. 결과 파싱: 'detections' 키에서 탐지 결과 리스트 가져오기
      final detectionsData = results['detections'] as List<dynamic>?;

      if (detectionsData != null && detectionsData.isNotEmpty) {
        // 탐지된 객체들을 DetectionResult 리스트로 변환
        final detectionResults = detectionsData.map((detectionMap) {
          // YOLO API 결과를 YOLOResult 객체로 변환
          final yoloResult = YOLOResult.fromMap(
            Map<String, dynamic>.from(detectionMap as Map),
          );

          // DetectionResult로 변환 (우리 앱에서 사용하는 형식)
          return DetectionResult(
            label: yoloResult.className,      // 객체 이름 (예: "bottle")
            confidence: yoloResult.confidence, // 신뢰도 (0.0 ~ 1.0)
            box: yoloResult.boundingBox,      // 바운딩박스 좌표 (Rect)
          );
        }).toList();

        if (!mounted) return;

        // UI에 탐지 결과 반영 (바운딩박스와 라벨 표시)
        setState(() {
          _detectionResults = detectionResults;
        });
      } else {
        // 탐지된 객체가 없음
        if (!mounted) return;
        setState(() {
          _detectionResults = [];
        });
      }
    } catch (e) {
      debugPrint('프레임 처리 실패: $e');
      // 에러가 발생해도 다음 프레임 처리는 계속 진행
    }
  }

  /// ============================================================
  /// 실시간 탐지 시작/중지
  /// ============================================================
  
  /// 실시간 객체 탐지를 시작합니다.
  /// 0.5초마다 _processFrame()을 호출하여 카메라 프레임을 분석합니다.
  void _startDetection() {
    // 모델과 카메라가 준비되었는지 확인
    if (!_isModelInitialized || !_isCameraActive) return;
    
    // 기존 타이머가 있으면 취소 (중복 실행 방지)
    _detectionTimer?.cancel();
    
    // 0.5초마다 프레임 처리하는 타이머 시작
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 500), // 0.5초마다 탐지
      (_) => _processFrame(),
    );
  }

  /// 실시간 객체 탐지를 중지합니다.
  /// 타이머를 취소하고 탐지 결과를 초기화합니다.
  void _stopDetection() {
    _detectionTimer?.cancel();
    setState(() {
      _detectionResults = [];
      _selectedDetectionLabel = null;
    });
  }

  /// ============================================================
  /// 리소스 정리
  /// ============================================================
  /// 위젯이 제거될 때 카메라, 타이머, 모델을 정리합니다.
  @override
  void dispose() {
    _cameraController?.dispose(); // 카메라 리소스 해제
    _detectionTimer?.cancel();     // 타이머 취소
    _yoloModel?.dispose();         // 모델 리소스 해제
    super.dispose();
  }

  /// ============================================================
  /// UI 빌드
  /// ============================================================
  /// 현재 상태에 따라 다른 화면을 표시합니다:
  /// - 시작 화면: 카메라 촬영 / 갤러리 업로드 버튼
  /// - 카메라 화면: 실시간 프리뷰 + 객체 탐지 결과
  /// - 이미지 프리뷰: 스캔 결과 표시
  @override
  Widget build(BuildContext context) {
    // 현재 여행 정보 가져오기 (목적지 등 규정 조회에 사용)
    final tripProvider = context.watch<TripProvider>();
    final currentTrip = tripProvider.currentTrip;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 현재 여행 이름
          Center(
            child: Column(
              children: [
                const Text(
                  '물품 스캔',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (currentTrip != null)
                  Text(
                    '${currentTrip.name} 기준',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 상태에 따라 다른 화면 표시
          if (!_isCameraActive && _selectedImage == null) 
            _buildStartOptions(), // 시작 화면 (카메라/갤러리 선택)
          if (_isCameraActive) 
            _buildCameraView(), // 카메라 프리뷰 + 실시간 탐지
          if (_selectedImage != null) 
            _buildImagePreview(), // 스캔 결과 화면
        ],
      ),
    );
  }

  /// ============================================================
  /// 시작 화면 빌드
  /// ============================================================
  /// 사용자가 카메라 촬영 또는 갤러리 업로드를 선택할 수 있는 화면입니다.
  Widget _buildStartOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // 카메라 아이콘
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            // 카메라 촬영 / 갤러리 업로드 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startCamera, // 카메라 시작
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('카메라 촬영'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage, // 갤러리에서 선택
                    icon: const Icon(Icons.upload),
                    label: const Text('사진 업로드'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================================
  /// 카메라 프리뷰 화면 빌드
  /// ============================================================
  /// 실시간 카메라 프리뷰와 객체 탐지 결과를 표시합니다.
  /// - 카메라 프리뷰
  /// - 탐지된 객체의 바운딩박스 오버레이
  /// - 탐지된 객체 목록 (가로 스크롤)
  /// - 촬영 / 취소 버튼
  Widget _buildCameraView() {
    // 카메라가 아직 초기화되지 않았으면 로딩 표시
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 카메라 프리뷰 영역
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 300,
                width: double.infinity,
                child: Stack(
                  children: [
                    // 1. 카메라 프리뷰 (가장 아래 레이어)
                    CameraPreview(_cameraController!),
                    
                    // 2. 바운딩박스 오버레이 (탐지된 객체 주변에 박스 표시)
                    if (_isModelInitialized)
                      ..._buildBoundingBoxes(),
                    
                    // 3. 모델 로딩 중 오버레이
                    if (_isModelLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text(
                                  '모델 로딩 중...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // 4. 웹 브라우저 권한 안내 (웹에서만 표시)
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
            
            // 탐지된 객체 목록 (가로 스크롤 가능한 칩 목록)
            if (_detectionResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _detectionResults.length,
                  itemBuilder: (context, index) {
                    final detection = _detectionResults[index];
                    final isSelected = _selectedDetectionLabel == detection.label;
                    
                    // 각 객체를 클릭 가능한 칩으로 표시
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          // 클릭하면 해당 객체를 선택
                          setState(() {
                            _selectedDetectionLabel = detection.label;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 객체 이름
                              Text(
                                detection.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // 신뢰도 (퍼센트)
                              Text(
                                '${(detection.confidence * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // 촬영 / 취소 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    // 객체를 선택했거나 탐지 결과가 없을 때만 촬영 가능
                    onPressed: _selectedDetectionLabel != null ||
                            _detectionResults.isEmpty
                        ? _capturePhoto
                        : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('촬영하기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _stopCamera, // 카메라 종료
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

  /// ============================================================
  /// 바운딩박스 오버레이 생성
  /// ============================================================
  /// 탐지된 각 객체 주변에 사각형 박스와 라벨을 표시합니다.
  /// 선택된 객체는 더 두꺼운 테두리로 표시됩니다.
  List<Widget> _buildBoundingBoxes() {
    if (_detectionResults.isEmpty) return [];

    return _detectionResults.map((detection) {
      final isSelected = _selectedDetectionLabel == detection.label;
      
      // 각 탐지 결과에 대해 Positioned 위젯 생성 (카메라 프리뷰 위에 오버레이)
      return Positioned(
        left: detection.box.left,   // 박스의 X 좌표
        top: detection.box.top,      // 박스의 Y 좌표
        width: detection.box.width,  // 박스의 너비
        height: detection.box.height, // 박스의 높이
        child: GestureDetector(
          onTap: () {
            // 박스를 탭하면 해당 객체 선택
            setState(() {
              _selectedDetectionLabel = detection.label;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary // 선택됨: 파란색
                    : Colors.green,                          // 미선택: 초록색
                width: isSelected ? 3 : 2, // 선택된 객체는 더 두꺼운 테두리
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                // 박스 위에 라벨과 신뢰도 표시
                Positioned(
                  top: -20, // 박스 위쪽에 표시
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  /// ============================================================
  /// 이미지 프리뷰 및 스캔 결과 화면 빌드
  /// ============================================================
  /// 촬영하거나 업로드한 이미지를 표시하고 스캔 결과를 보여줍니다.
  Widget _buildImagePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 선택된 이미지 표시
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: FutureBuilder<Uint8List>(
                  future: _selectedImage!.readAsBytes(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Image.memory(snap.data!, fit: BoxFit.cover);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 스캔 중 표시
            if (_isScanning) _buildScanningIndicator(),
            
            // 스캔 결과 표시
            if (_scanResult != null) _buildScanResult(),
            
            const SizedBox(height: 16),
            
            // 액션 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _scanResult != null ? _addToPackingList : null,
                    child: const Text('짐 리스트에 추가'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetScan, // 다시 스캔하기
                    child: const Text('다시 스캔'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'AI가 물품을 분석하고 있어요...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.75,
          backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ],
    );
  }

  Widget _buildScanResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '스캔 결과',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '정확도 ${_scanResult!.confidence}%',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),

        // 🔹 Preview API 로딩 상태 표시
        if (_isPreviewLoading) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                '상세 판정 불러오는 중...',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _scanResult!.item,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _scanResult!.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_scanResult!.volume != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '용량: ${_scanResult!.volume}',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_scanResult!.weight != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '용량: ${_scanResult!.weight}',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildLuggageStatus(
                        '기내 수하물',
                        _scanResult!.carryOnAllowed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLuggageStatus(
                        '위탁 수하물',
                        _scanResult!.checkedAllowed,
                      ),
                    ),
                  ],
                ),

                if (_scanResult!.restrictions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '주의사항',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._scanResult!.restrictions.map(
                        (restriction) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              restriction,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 🔹 여기서 Preview API 호출 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                    _isPreviewLoading ? null : _openPreviewForScanResult,
                    icon: const Icon(Icons.info_outline),
                    label: const Text('상세 판정 보기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLuggageStatus(String title, bool allowed) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: allowed ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: allowed ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.cancel,
            color: allowed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            allowed ? '허용' : '불가',
            style: TextStyle(
              fontSize: 10,
              color: allowed
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================================
  /// 카메라 제어 메서드들
  /// ============================================================
  
  /// 카메라를 시작하고 실시간 탐지를 시작합니다.
  Future<void> _startCamera() async {
    // 카메라가 초기화되지 않았으면 초기화
    if (_cameraController == null) {
      await _initializeCamera();
    }
    
    // 카메라가 준비되었으면 활성화
    if (_cameraController != null &&
        _cameraController!.value.isInitialized) {
      setState(() {
        _isCameraActive = true;
      });
      // 실시간 객체 탐지 시작
      _startDetection();
    }
  }

  /// 카메라를 중지하고 탐지를 중단합니다.
  void _stopCamera() {
    // 탐지 중지
    _stopDetection();
    setState(() {
      _isCameraActive = false;
      _detectionResults = [];
      _selectedDetectionLabel = null;
    });
  }

  /// 현재 프레임을 촬영하고 스캔 결과를 처리합니다.
  Future<void> _capturePhoto() async {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized) {
      // 탐지 중지 (촬영 후에는 탐지 불필요)
      _stopDetection();
      
      // 현재 프레임을 이미지로 캡처
      final image = await _cameraController!.takePicture();
      setState(() {
        _selectedImage = image;
        _isCameraActive = false; // 카메라 비활성화
      });
      
      // 탐지 결과가 있으면 그것을 사용, 없으면 시뮬레이션 사용
      if (_selectedDetectionLabel != null || _detectionResults.isNotEmpty) {
        _processScanResult(); // YOLO 탐지 결과를 스캔 결과로 변환
      } else {
        _simulateScan(); // 탐지 결과가 없으면 모의 스캔 결과 생성
      }
    }
  }

  /// ============================================================
  /// 탐지 결과 처리
  /// ============================================================
  /// YOLO 탐지 결과를 ScanResult로 변환하고 Preview API를 호출합니다.
  Future<void> _processScanResult() async {
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    // 1. 사용할 탐지 결과 선택
    // - 사용자가 선택한 객체가 있으면 그것 사용
    // - 없으면 신뢰도가 가장 높은 객체 사용
    DetectionResult? selectedDetection;
    if (_selectedDetectionLabel != null && _detectionResults.isNotEmpty) {
      try {
        // 선택된 라벨과 일치하는 탐지 결과 찾기
        selectedDetection = _detectionResults.firstWhere(
          (d) => d.label == _selectedDetectionLabel,
        );
      } catch (e) {
        // 찾지 못하면 첫 번째 결과 사용
        if (_detectionResults.isNotEmpty) {
          selectedDetection = _detectionResults.first;
        }
      }
    } else if (_detectionResults.isNotEmpty) {
      // 컨피던스가 가장 높은 결과 선택
      selectedDetection = _detectionResults.reduce(
        (a, b) => a.confidence > b.confidence ? a : b,
      );
    }

    if (selectedDetection != null) {
      // 2. 탐지 결과를 ScanResult로 변환
      // 라벨을 카테고리로 매핑하는 헬퍼 함수
      String getCategory(String label) {
        final categoryMap = {
          'toothpaste': '화장품',
          'toothbrush': '화장품',
          'cosmetics': '화장품',
          'bottle': '액체류',
          'battery': '전자기기',
          'power bank': '전자기기',
          'cell phone': '전자기기',
          'fan': '전자기기',
          'glasses': '액세서리',
          'clothes': '의류',
          'person': '기타',
        };
        return categoryMap[label.toLowerCase()] ?? '기타';
      }

      // ScanResult 생성
      setState(() {
        _scanResult = ScanResult(
          item: selectedDetection!.label, // 객체 이름
          category: getCategory(selectedDetection.label), // 카테고리
          carryOnAllowed: true, // TODO: 실제 규정 확인 로직 추가
          checkedAllowed: true, // TODO: 실제 규정 확인 로직 추가
          restrictions: [], // TODO: 실제 규정 확인 로직 추가
          confidence: (selectedDetection.confidence * 100).toInt(), // 신뢰도 (%)
        );
        _isScanning = false;
      });

      // 3. Preview API 호출하여 상세 규정 조회 및 화면 이동
      await _openPreviewForScanResult();
    } else {
      // 탐지 결과가 없으면 기존 시뮬레이션 사용
      _simulateScan();
    }
  }

  /// ============================================================
  /// 갤러리 이미지 선택
  /// ============================================================
  /// 사용자가 갤러리에서 이미지를 선택하면 호출됩니다.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
      // 갤러리 이미지는 YOLO 탐지가 없으므로 시뮬레이션 사용
      _simulateScan();
    }
  }

  /// ============================================================
  /// 모의 스캔 결과 생성
  /// ============================================================
  /// YOLO 탐지가 실패하거나 갤러리 이미지를 사용할 때 
  /// 임시로 모의 스캔 결과를 생성합니다.
  /// 실제 구현에서는 AI/Preview API + 이미지 분석 연동 예정
  Future<void> _simulateScan() async {
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    // 스캔 중 시뮬레이션 (2초 대기)
    await Future.delayed(const Duration(seconds: 2));

    // 모의 결과 데이터 (랜덤하게 선택)
    final mockResults = [
      ScanResult(
        item: "화장품 (토너)",
        category: "액체류",
        volume: "150ml",
        carryOnAllowed: true,
        checkedAllowed: true,
        restrictions: ["100ml 이하 용기에 담아야 함", "투명 지퍼백에 보관"],
        confidence: 92,
      ),
      ScanResult(
        item: "보조배터리",
        category: "전자기기",
        weight: "20,000mAh",
        carryOnAllowed: true,
        checkedAllowed: false,
        restrictions: ["기내 수하물만 가능", "100Wh 이하만 허용"],
        confidence: 88,
      ),
      ScanResult(
        item: "헤어드라이어",
        category: "전자기기",
        carryOnAllowed: true,
        checkedAllowed: true,
        restrictions: ["전압 확인 필요", "플러그 어댑터 준비"],
        confidence: 95,
      ),
    ];

    // 랜덤하게 하나 선택 (현재 시간 기반)
    setState(() {
      _scanResult =
      mockResults[DateTime.now().millisecondsSinceEpoch % mockResults.length];
      _isScanning = false;
    });
  }

  /// ============================================================
  /// 스캔 초기화
  /// ============================================================
  /// 모든 스캔 관련 상태를 초기화하여 처음부터 다시 시작할 수 있게 합니다.
  void _resetScan() {
    setState(() {
      _selectedImage = null;
      _scanResult = null;
      _isScanning = false;
      _isPreviewLoading = false;
    });
  }

  /// ============================================================
  /// 짐 리스트에 추가
  /// ============================================================
  /// 스캔 결과를 짐 리스트에 추가합니다.
  /// TODO: 나중에 PackingProvider랑 실제 연동 (현재 Trip 기준으로 추가)
  void _addToPackingList() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('짐 리스트에 추가되었습니다')),
    );
  }

  // =========================================================
  // 🔹 Preview API 연동 부분
  // =========================================================

  /// ============================================================
  /// Preview API 호출 및 상세 판정 화면 이동
  /// ============================================================
  /// 스캔 결과를 기반으로 Preview API를 호출하여 
  /// 아이템의 상세 규정 정보를 조회하고 ItemPreviewScreen으로 이동합니다.
  Future<void> _openPreviewForScanResult() async {
    if (_scanResult == null) return;

    // 현재 여행 정보 가져오기
    final tripProvider = context.read<TripProvider>();
    final currentTrip = tripProvider.currentTrip;

    // 여행 정보가 없으면 에러 표시
    if (currentTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 여행 정보를 설정해 주세요.')),
      );
      return;
    }

    setState(() {
      _isPreviewLoading = true;
    });

    try {
      final previewProvider = context.read<PreviewProvider>();

      /// 목적지 문자열에서 공항 코드 추출
      /// 예: "일본 나리타(NRT)" → "NRT"
      String extractAirportCode(String destination) {
        final start = destination.indexOf('(');
        final end = destination.indexOf(')');

        // 괄호 안에 3글자 알파벳 코드가 있으면 추출
        if (start != -1 && end != -1 && end > start + 1) {
          final inside = destination.substring(start + 1, end).trim();
          final isCode = inside.length == 3 &&
              RegExp(r'^[A-Za-z]+$').hasMatch(inside);
          if (isCode) return inside.toUpperCase();
        }

        // 괄호가 없으면 앞 3글자 정도를 코드처럼 사용하는 임시 로직
        final trimmed = destination.trim();
        if (trimmed.length >= 3) {
          return trimmed.substring(0, 3).toUpperCase();
        }
        // 완전 없으면 그냥 NRT 같은 기본값 사용 (임시)
        return 'NRT';
      }

      // 여행 정보에서 공항 코드 추출
      // TODO: 좌석 등급/항공사 정보는 아직 Trip에 없으므로 임시값 사용
      const fromAirport = 'ICN'; // 인천공항 (출발지)
      final toAirport = extractAirportCode(currentTrip.destination); // 목적지 공항 코드
      const airlineCode = 'KE'; // TODO: Trip에 항공사 필드 추가 후 교체
      const cabinClass = 'economy'; // TODO: Trip에 좌석 등급 필드 추가 후 교체

      // Preview API 요청 데이터 생성
      // TODO: 아이템 정보도 아직 구조화 안되어 있으니 대략적인 값 사용
      final request = PreviewRequest(
        label: _scanResult!.item, // 스캔된 아이템 이름 (예: "bottle")
        locale: 'ko-KR', // 한국어
        reqId: DateTime.now().millisecondsSinceEpoch.toString(), // 요청 ID
        itinerary: Itinerary(
          from: fromAirport, // 출발지
          to: toAirport,     // 목적지
          via: const [],     // 경유지 없음
          rescreening: false, // 재검색 여부
        ),
        segments: [
          Segment(
            leg: '$fromAirport-$toAirport', // 구간
            operating: airlineCode,           // 항공사 코드
            cabinClass: cabinClass,         // 좌석 등급
          ),
        ],
        itemParams: ItemParams(
          volumeMl: 100, // TODO: _scanResult.volume 파싱해서 반영 가능
          wh: 0,         // 와트시
          count: 1,      // 개수
          abvPercent: 0, // 알코올 도수
          weightKg: 0.2, // 무게 (kg)
          bladeLengthCm: 0, // 칼날 길이
        ),
        dutyFree: DutyFree(
          isDf: false,      // 면세품 여부
          stebSealed: false, // STEB 봉인 여부
        ),
      );

      // Preview API 호출
      await previewProvider.fetchPreview(request);

      if (!mounted) return;

      // 에러 처리
      if (previewProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '아이템 판정 조회 중 오류가 발생했습니다.\n${previewProvider.errorMessage}',
            ),
          ),
        );
      } else if (previewProvider.preview != null) {
        // 성공: ItemPreviewScreen으로 이동하여 상세 규정 표시
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemPreviewScreen(
              data: previewProvider.preview!,
            ),
          ),
        );
      }
    } finally {
      // 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
    }
  }
}

// ============================================================
// 데이터 클래스들
// ============================================================

/// YOLO 모델이 탐지한 객체의 정보를 담는 클래스
/// 카메라 프리뷰에 바운딩박스를 그리기 위해 사용됩니다.
class DetectionResult {
  final String label;      // 객체 이름 (예: "bottle", "battery")
  final double confidence; // 신뢰도 (0.0 ~ 1.0)
  final Rect box;          // 바운딩박스 좌표 (카메라 프리뷰 기준)

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.box,
  });
}

/// 스캔 결과를 담는 클래스
/// YOLO 탐지 결과를 변환하거나 시뮬레이션으로 생성한 데이터입니다.
class ScanResult {
  final String item;              // 아이템 이름
  final String category;          // 카테고리 (예: "액체류", "전자기기")
  final String? volume;           // 용량 (선택적, 예: "150ml")
  final String? weight;           // 무게 (선택적, 예: "20,000mAh")
  final bool carryOnAllowed;      // 기내 수하물 허용 여부
  final bool checkedAllowed;      // 위탁 수하물 허용 여부
  final List<String> restrictions; // 주의사항 목록
  final int confidence;           // 스캔 신뢰도 (%)

  ScanResult({
    required this.item,
    required this.category,
    this.volume,
    this.weight,
    required this.carryOnAllowed,
    required this.checkedAllowed,
    required this.restrictions,
    required this.confidence,
  });
}
