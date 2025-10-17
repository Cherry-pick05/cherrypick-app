import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// 플랫폼별 조건부 import
import 'package:flutter/foundation.dart' show kIsWeb;

// 웹이 아닌 경우에만 카메라 패키지 import
import 'package:camera/camera.dart' if (dart.library.html) 'package:camera/camera_web.dart';

class ItemScanner extends StatefulWidget {
  const ItemScanner({super.key});

  @override
  State<ItemScanner> createState() => _ItemScannerState();
}

class _ItemScannerState extends State<ItemScanner> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraActive = false;
  bool _isScanning = false;
  XFile? _selectedImage;
  ScanResult? _scanResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // 웹에서는 카메라 초기화 건너뛰기
    if (kIsWeb) {
      setState(() {});
      return;
    }
    
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('카메라 초기화 실패: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              '물품 스캔',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!_isCameraActive && _selectedImage == null) _buildStartOptions(),
          if (_isCameraActive) _buildCameraView(),
          if (_selectedImage != null) _buildImagePreview(),
        ],
      ),
    );
  }

  Widget _buildStartOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('카메라 촬영'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
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

  Widget _buildCameraView() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  CameraPreview(_cameraController!),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                  onPressed: _stopCamera,
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

  Widget _buildImagePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: kIsWeb 
                ? Image.network(
                    _selectedImage!.path,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(_selectedImage!.path),
                    fit: BoxFit.cover,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isScanning) _buildScanningIndicator(),
          if (_scanResult != null) _buildScanResult(),
          const SizedBox(height: 16),
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
                  onPressed: _resetScan,
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
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '정확도 ${_scanResult!.confidence}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _scanResult!.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '용량: ${_scanResult!.volume}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '용량: ${_scanResult!.weight}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  ..._scanResult!.restrictions.map((restriction) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            restriction,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
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
              color: allowed ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startCamera() async {
    if (_cameraController != null) {
      await _cameraController!.initialize();
      setState(() {
        _isCameraActive = true;
      });
    }
  }

  void _stopCamera() {
    setState(() {
      _isCameraActive = false;
    });
  }

  Future<void> _capturePhoto() async {
    if (_cameraController != null) {
      final image = await _cameraController!.takePicture();
      setState(() {
        _selectedImage = image;
        _isCameraActive = false;
      });
      _simulateScan();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
      _simulateScan();
    }
  }

  Future<void> _simulateScan() async {
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    // 실제 구현에서는 AI API 호출
    await Future.delayed(const Duration(seconds: 2));

    // 모의 결과 데이터
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

    setState(() {
      _scanResult = mockResults[DateTime.now().millisecondsSinceEpoch % mockResults.length];
      _isScanning = false;
    });
  }

  void _resetScan() {
    setState(() {
      _selectedImage = null;
      _scanResult = null;
      _isScanning = false;
    });
  }

  void _addToPackingList() {
    // 짐 리스트에 추가하는 로직
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('짐 리스트에 추가되었습니다')),
    );
  }
}

class ScanResult {
  final String item;
  final String category;
  final String? volume;
  final String? weight;
  final bool carryOnAllowed;
  final bool checkedAllowed;
  final List<String> restrictions;
  final int confidence;

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
