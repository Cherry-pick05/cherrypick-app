import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../models/packing_item.dart';
import '../providers/packing_provider.dart';
import '../models/bag.dart' as bag;

// --- 새로 만들 camera_detector_view 임포트 ---
// widgets 폴더에 있으므로, screens 폴더로 한 단계 위로 올라갑니다.
import '../screens/object_detection/camera_detector_view.dart';
// 기존 camera, mlkit 관련 임포트는 모두 삭제합니다.

// (1) 아이템 추가용 BottomSheet 위젯 정의
class AddItemSheet extends StatefulWidget {
  final String initialLabel;
  final String initialCategory;
  final List<bag.Bag> bags;
  final String? initialLocation;
  final Function({required String label, required String category, required String bagId, String? location}) onConfirm;

  const AddItemSheet({
    super.key,
    required this.initialLabel,
    required this.initialCategory,
    required this.bags,
    this.initialLocation,
    required this.onConfirm,
  });

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late TextEditingController _labelController;
  late TextEditingController _locationController;
  bag.Bag? _selectedBag;
  String? _selectedCategory;

  // 체리픽 탭에서 쓰는 것과 동일하게, 가방 type에 대한 한글 라벨 제공
  final Map<String, String> _typeLabels = const {
    'carry-on': '기내용',
    'checked': '위탁용',
    'personal': '개인 소지품',
  };

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
    _locationController = TextEditingController(text: widget.initialLocation ?? '');
    _selectedCategory = widget.initialCategory;
    if (widget.bags.isNotEmpty) {
      _selectedBag = widget.bags.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('가방 선택', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<bag.Bag>(
            value: _selectedBag,
            items: widget.bags
                .map((bag) => DropdownMenuItem(
                      value: bag,
                      child: Text(_typeLabels[bag.type] ?? bag.name),
                    ))
                .toList(),
            onChanged: (bag) => setState(() => _selectedBag = bag),
          ),
          const SizedBox(height: 8),
          const Text('아이템명 수정', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _labelController),
          const SizedBox(height: 8),
          const Text('카테고리', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: _selectedCategory,
            items: ['전자기기', '액체류', '서류', '기타']
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val)=>setState(()=>_selectedCategory=val),
          ),
          const SizedBox(height: 8),
          const Text('가방 내 위치', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _locationController, decoration: const InputDecoration(hintText: '예) 앞주머니')), 
          const SizedBox(height:16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _selectedBag!=null && _labelController.text.isNotEmpty && _selectedCategory!=null ? () {
                  widget.onConfirm(label: _labelController.text, category: _selectedCategory!, bagId: _selectedBag!.id, location: _locationController.text);
                } : null,
                child: const Text("짐에 추가"),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class ItemScanner extends StatefulWidget {
  const ItemScanner({super.key});

  @override
  State<ItemScanner> createState() => _ItemScannerState();
}

// 현재 화면이 어떤 뷰를 보여줘야 하는지 관리하는 Enum(열거형)
enum ScanView {
  options, // "카메라/업로드" 선택
  camera,  // 실시간 카메라 감지
  preview  // 촬영/업로드 후 결과 확인
}

class _ItemScannerState extends State<ItemScanner> {
  // --- UI 상태 변수 ---
  // 앱 시작 시 "옵션" 뷰로 시작하도록 _currentView 상태를 설정합니다.
  ScanView _currentView = ScanView.options;
  // 촬영되거나 갤러리에서 업로드된 이미지 바이트를 저장하는 변수입니다.
  Uint8List? _selectedImageBytes;

  // --- 스캔 결과 변수 ---
  // "AI가 물품을 분석하고 있어요..." 인디케이터를 표시할지 결정합니다.
  bool _isScanning = false;
  // 스캔 결과(모의 데이터)를 저장하는 변수입니다.
  ScanResult? _scanResult;

  // CameraController, ObjectDetector 등 복잡한 로직은
  // 모두 'camera_detector_view.dart'로 이동했으므로 여기서 삭제합니다.

  @override
  void initState() {
    super.initState();
    // 카메라 및 ML Kit 초기화 로직 제거
  }

  @override
  void dispose() {
    // 컨트롤러 해제 로직 제거
    super.dispose();
  }

  // --- UI 빌드 로직 ---
  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView: 스캔 결과가 길어져도 스크롤이 가능하게 합니다.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "물품 스캔" 타이틀
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

          // AnimatedSwitcher: _currentView의 값에 따라
          // 세 가지 뷰(options, camera, preview) 중 하나로 부드럽게 전환합니다.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300), // 0.3초 동안 전환
            child: _buildCurrentView(), // 현재 뷰를 빌드하는 함수 호출
          ),
        ],
      ),
    );
  }

  // _currentView의 값에 따라 적절한 위젯을 반환하는 헬퍼 함수
  Widget _buildCurrentView() {
    switch (_currentView) {
    // 1. "옵션" 뷰일 경우
      case ScanView.options:
      // "카메라 촬영", "사진 업로드" 버튼 표시
        return _buildStartOptions();

    // 2. "카메라" 뷰일 경우
      case ScanView.camera:
      // 실시간 카메라 감지 뷰(새 파일)를 표시
        return CameraDetectorView(
          // AnimatedSwitcher가 위젯을 구분할 수 있도록 Key를 줍니다.
          key: const ValueKey('camera_view'),

          // '촬영하기' 버튼을 누르면 이 콜백이 실행됨
          onPhotoCaptured: (Uint8List? imageBytes, List<String> labels) {
            // 카메라 뷰에서 이미지 바이트(imageBytes)와 라벨 리스트(labels)를 받음
            setState(() {
              _selectedImageBytes = imageBytes; // 받은 이미지 바이트 저장
              _currentView = ScanView.preview; // UI를 '결과 확인' 뷰로 전환
            });
            // 받은 라벨 중 첫 번째 항목(없으면 null)을 비즈니스 로직으로 전달
            _getScanResult(labels.firstOrNull);
          },
          // '취소' 버튼을 누르면 이 콜백이 실행됨
          onCancel: () {
            // UI를 다시 '옵션 선택' 뷰로 전환
            setState(() {
              _currentView = ScanView.options;
            });
          },
        );

    // 3. "결과 확인" 뷰일 경우
      case ScanView.preview:
      // 촬영/업로드된 이미지와 스캔 결과 표시
        return _buildImagePreview();
    }
  }

  // "카메라 촬영", "사진 업로드" 버튼 UI
  Widget _buildStartOptions() {
    return Card(
      key: const ValueKey('options'), // AnimatedSwitcher를 위한 Key
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
                    // _startCamera 대신 UI 상태 변경
                    onPressed: () {
                      // 버튼을 누르면 _currentView 상태를 'camera'로 변경
                      setState(() {
                        _currentView = ScanView.camera; // 카메라 뷰로 전환
                      });
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('카메라 촬영'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage, // 갤러리에서 이미지 선택
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

  // 이미지 프리뷰 및 결과 UI (수정됨)
  Widget _buildImagePreview() {
    // _selectedImageBytes가 null이 아닐 때만 호출됩니다.
    if (_selectedImageBytes == null) {
      // 혹시 모르니 빈 컨테이너 반환
      return Container(key: const ValueKey('preview_empty'));
    }

    return Card(
      key: const ValueKey('preview'), // AnimatedSwitcher를 위한 Key
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 촬영/업로드된 이미지 표시
            if (_selectedImageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0, // 1:1 비율 강제
                  child: Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              // 이미지가 없는 경우 (웹에서 바코드만 감지된 경우)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '아이템이 감지되었습니다',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // "분석 중..." 인디케이터 표시
            if (_isScanning) _buildScanningIndicator(),

            // 스캔 결과 표시
            if (_scanResult != null) _buildScanResult(),

            const SizedBox(height: 16),

            // "짐 리스트 추가" / "다시 스캔" 버튼
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

  // --- 이하 비즈니스 로직 및 UI 빌더 ---
  // 이 위젯들은 UI의 '부품'이며 상태에 따라 보였다/사라졌다 합니다.

  // "AI가 물품을 분석하고 있어요..." 인디케이터 UI
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
          value: null, // 0.75 대신 무한 로딩으로 변경
          backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ],
    );
  }

  // 스캔 결과(모의 데이터)를 표시하는 UI
  Widget _buildScanResult() {
    // _scanResult가 null이 아닐 때만 호출됩니다.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // "스캔 결과" 타이틀 및 정확도
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
        // 결과 상세 카드
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아이템 이름 및 카테고리
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
                // 용량
                if (_scanResult!.volume != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
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
                // 무게/사양
                if (_scanResult!.weight != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '사양: ${_scanResult!.weight}',
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
                // 기내/위탁 수하물 허용 여부
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
                // 주의사항
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
                            margin:
                            const EdgeInsets.only(top: 6, right: 8),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  // "기내 수하물" / "위탁 수하물" UI를 그리는 작은 위젯
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

  // 갤러리에서 이미지 선택 로직
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageBytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = imageBytes;
        _currentView = ScanView.preview; // (수정) 뷰 상태를 '결과 확인'으로 변경
      });

      // TODO: 갤러리 이미지도 ML Kit으로 분석하는 로직 추가 필요
      // (현재는 갤러리 이미지를 분석하지 않고 null을 전달)
      _getScanResult(null);
    }
  }

  // 비즈니스 로직: 감지된 라벨을 인자로 받아 모의 결과를 생성
  Future<void> _getScanResult(String? detectedItem) async {
    // 1. "분석 중..." UI 표시
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    // 2. AI API 호출 (지금은 2초 대기)
    debugPrint("감지된 아이템 (API로 전송): $detectedItem");
    await Future.delayed(const Duration(seconds: 2));

    // 3. 모의 결과 데이터베이스
    final mockResults = {
      "bottle": ScanResult(
        item: "화장품 (토너)",
        category: "액체류",
        volume: "150ml",
        carryOnAllowed: true, checkedAllowed: true,
        restrictions: ["100ml 이하 용기에 담아야 함", "투명 지퍼백에 보관"],
        confidence: 92,
      ),
      "power bank": ScanResult(
        item: "보조배터리",
        category: "전자기기",
        weight: "20,000mAh",
        carryOnAllowed: true, checkedAllowed: false,
        restrictions: ["기내 수하물만 가능", "100Wh 이하만 허용"],
        confidence: 88,
      ),
      "hair dryer": ScanResult(
        item: "헤어드라이어",
        category: "전자기기",
        carryOnAllowed: true, checkedAllowed: true,
        restrictions: ["전압 확인 필요", "플러그 어댑터 준비"],
        confidence: 95,
      ),
      "default": ScanResult(
        item: detectedItem ?? "알 수 없음", // (수정) 감지된 라벨을 기본값으로 사용
        category: "기타",
        carryOnAllowed: true, checkedAllowed: true,
        restrictions: ["항공사 규정 확인 필요"],
        confidence: 00,
      ),
    };

    ScanResult result;
    // 4. 감지된 라벨(소문자)이 모의 데이터에 있는지 확인
    if (detectedItem != null && mockResults.containsKey(detectedItem.toLowerCase())) {
      // 5. 있으면 해당 결과 사용
      result = mockResults[detectedItem.toLowerCase()]!;
    } else {
      // 6. 없으면 'default' 결과 사용
      result = mockResults["default"]!;
    }

    // 7. 결과 UI 표시
    setState(() {
      _scanResult = result;
      _isScanning = false;
    });
  }

  // "다시 스캔" 버튼 로직
  void _resetScan() {
    // 모든 상태를 초기화하고 '옵션' 뷰로 되돌아감
    setState(() {
      _selectedImageBytes = null;
      _scanResult = null;
      _isScanning = false;
      _currentView = ScanView.options; // (수정) 다시 스캔 시 옵션 뷰로
    });
  }

  // (2) Provider에서 현재 가방 목록을 받아옴
  void _addToPackingList() {
    final bagList = context.read<PackingProvider>().bags;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return AddItemSheet(
            initialLabel: _scanResult?.item ?? '',
            initialCategory: _scanResult?.category ?? '기타',
            bags: bagList, // <-- id 리스트가 아닌 모델 리스트 전달!
            initialLocation: '',
            onConfirm: ({required label, required category, required bagId, String? location}) {
              // (3) Provider를 통해 실제 짐리스트에 추가
              final newItem = PackingItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: label,
                category: category,
                packed: false,
                bagId: bagId,
                location: location ?? '',
              );
              context.read<PackingProvider>().addItem(newItem);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('짐에 추가 완료')));
            },
          );
        });
  }
}

// 스캔 결과 데이터 모델 (ScanResult 클래스)
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
