/// ============================================================
/// 아이템 규정 미리보기 화면 (ItemPreviewScreen)
/// ============================================================
/// 
/// 기능:
/// 1. Preview API로부터 받은 아이템 규정 정보를 표시
/// 2. 기내 수하물 / 위탁 수하물 허용 여부 표시
/// 3. 주의사항, 팁, 출처 등 상세 정보 표시
/// 4. allowSave=true일 때 아이템을 짐 리스트에 저장 가능
/// 
/// 사용되는 곳:
/// - ItemScanner에서 스캔 후 자동 이동 (allowSave=false)
/// - 다른 화면에서 규정만 확인할 때 (allowSave=false)
/// - 아이템 추가 다이얼로그에서 저장할 때 (allowSave=true)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/preview_response.dart';
import '../widgets/item_status_styles.dart';
import '../service/item_api.dart';
import '../providers/packing_provider.dart';

/// 아이템 규정 미리보기 화면
/// Preview API 응답 데이터를 받아서 규정 정보를 표시합니다.
class ItemPreviewScreen extends StatefulWidget {
  /// Preview API로부터 받은 규정 정보 데이터
  final PreviewResponse data;

  /// true: "아이템 리스트에 추가 / 취소" 버튼을 보여주고, 저장까지 담당
  /// false: 규정만 보여주는 읽기 전용 화면 (ItemScanner에서 올 때)
  final bool allowSave;

  /// allowSave=true 일 때만 쓰는 값들 (아이템 저장에 필요)
  final int? tripId;        // 여행 ID
  final int? bagId;         // 가방 ID
  final String? deviceUuid; // 기기 UUID
  final String? deviceToken; // 기기 토큰

  /// 사용자가 다이얼로그에서 직접 입력한 이름 (예: "옷")
  /// 이 값이 있으면 엔진이 준 title보다 우선 표시됩니다.
  final String? userLabel;

  const ItemPreviewScreen({
    super.key,
    required this.data,
    this.allowSave = false,
    this.tripId,
    this.bagId,
    this.deviceUuid,
    this.deviceToken,
    this.userLabel,
  });

  @override
  State<ItemPreviewScreen> createState() => _ItemPreviewScreenState();
}

class _ItemPreviewScreenState extends State<ItemPreviewScreen> {
  /// 아이템 저장 중인지 여부 (저장 버튼 비활성화용)
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    // Preview API 응답에서 규정 설명 정보 가져오기
    final narration = widget.data.narration;

    // narration이 없으면 에러 화면 표시
    if (narration == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('아이템')),
        body: const Center(
          child: Text('판정 정보를 불러올 수 없습니다.'),
        ),
      );
    }

    // 기내 수하물 / 위탁 수하물 상태 스타일 가져오기
    // statusLabel을 기반으로 색상, 아이콘 등을 결정
    final carryStatus =
    statusStyleMap[statusFromLabel(narration.carryOnCard.statusLabel)]!;
    final checkedStatus =
    statusStyleMap[statusFromLabel(narration.checkedCard.statusLabel)]!;

    // AI 팁을 관련도 순으로 정렬 (높은 관련도가 먼저)
    final tips = [...widget.data.aiTips]
      ..sort((a, b) => b.relevance.compareTo(a.relevance));

    // ============================================================
    // 화면에 표시할 제목 결정
    // ============================================================
    // 우선순위: 사용자가 입력한 userLabel > 엔진이 준 title
    final displayTitle =
    (widget.userLabel != null && widget.userLabel!.isNotEmpty)
        ? widget.userLabel!
        : narration.title;

    // ============================================================
    // 칩(chip) 텍스트 목록 생성 (중복 제거)
    // ============================================================
    // userLabel → resolved.label → canonical 순서로 추가
    final String? userLabel = widget.userLabel?.trim();
    final String resolvedLabel = widget.data.resolved.label.trim();
    final String canonical = widget.data.resolved.canonical.trim();

    final List<String> chips = [];
    void addChip(String? value) {
      if (value == null) return;
      final v = value.trim();
      if (v.isEmpty) return;
      if (!chips.contains(v)) { // 중복 제거
        chips.add(v);
      }
    }

    addChip(userLabel);
    addChip(resolvedLabel);
    addChip(canonical);

    return Scaffold(
      appBar: AppBar(title: const Text('아이템 규정 미리보기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ============================================================
          // A. 헤더: 아이템 이름 + 칩 목록
          // ============================================================
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이템 이름 (userLabel 또는 엔진 title)
              Text(
                displayTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // 관련 라벨들을 칩으로 표시 (userLabel, resolved.label, canonical)
              if (chips.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: chips.map((t) => _SmallChip(t)).toList(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ============================================================
          // B. 판정 카드 2개: 기내 수하물 / 위탁 수하물
          // ============================================================
          // 각 카드는 허용/불가 여부와 간단한 이유를 표시합니다.
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  label: '기내 수하물',
                  statusLabel: narration.carryOnCard.statusLabel, // 예: "허용", "제한"
                  shortReason: narration.carryOnCard.shortReason, // 간단한 이유
                  style: carryStatus, // 색상, 아이콘 등 스타일
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusCard(
                  label: '위탁 수하물',
                  statusLabel: narration.checkedCard.statusLabel,
                  shortReason: narration.checkedCard.shortReason,
                  style: checkedStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ============================================================
          // C. 배지 영역: 아이템의 특성을 나타내는 태그들
          // ============================================================
          // 예: "액체", "전자기기", "화장품" 등
          if (narration.badges.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: narration.badges
                  .map(
                    (b) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    b,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ============================================================
          // D. 주의사항 목록 (bullets)
          // ============================================================
          // 규정에 대한 상세 설명을 불릿 포인트로 표시
          if (narration.bullets.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: narration.bullets
                  .map(
                    (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                      Expanded(
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ============================================================
          // E. AI 팁: 관련도가 높은 상위 3개만 표시
          // ============================================================
          if (tips.isNotEmpty) ...[
            const Text(
              '팁',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            ...tips.take(3).map( // 상위 3개만
                  (tip) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  tip.text,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ============================================================
          // F. 출처 / 풋노트: 규정 정보의 출처와 추가 설명
          // ============================================================
          if (narration.sources.isNotEmpty || narration.footnote.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                // 출처 목록
                if (narration.sources.isNotEmpty)
                  Text(
                    '출처: ${narration.sources.join(' · ')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                // 풋노트 (추가 설명)
                if (narration.footnote.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    narration.footnote,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),

      // ============================================================
      // 하단 버튼 영역: allowSave=true일 때만 표시
      // ============================================================
      // ItemScanner에서 올 때는 allowSave=false이므로 버튼이 없습니다.
      bottomNavigationBar: widget.allowSave
          ? SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // 취소 버튼: 화면을 닫고 돌아감
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null // 저장 중이면 비활성화
                      : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              // 저장 버튼: 아이템을 서버에 저장하고 짐 리스트에 추가
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving ? null : _onConfirmSave,
                  child: _isSaving
                      ? const SizedBox( // 저장 중이면 로딩 인디케이터 표시
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('아이템 리스트에 추가'),
                ),
              ),
            ],
          ),
        ),
      )
          : null, // allowSave=false면 버튼 없음
    );
  }

  /// ============================================================
  /// 아이템 저장 확인
  /// ============================================================
  /// 사용자가 "아이템 리스트에 추가" 버튼을 눌렀을 때 호출됩니다.
  /// Preview API 응답 데이터를 서버에 저장하고 짐 리스트에 추가합니다.
  Future<void> _onConfirmSave() async {
    // 필수 정보가 모두 있는지 확인
    if (widget.tripId == null ||
        widget.bagId == null ||
        widget.deviceUuid == null ||
        widget.deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('여행/기기 정보가 없어 저장할 수 없어요.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final api = ItemApiService();

      // 1. 서버에 아이템 저장
      await api.saveItem(
        deviceUuid: widget.deviceUuid!,
        deviceToken: widget.deviceToken!,
        bagId: widget.bagId!,
        tripId: widget.tripId!,
        preview: widget.data, // Preview API 응답 데이터
        reqId: widget.data.engine.reqId, // 요청 ID
        userLabel: widget.userLabel, // 사용자가 입력한 이름 (있으면)
      );

      // 2. 저장 후 가방/아이템 목록을 서버에서 다시 로딩
      //    (저장된 아이템이 리스트에 반영되도록)
      final packingProvider = context.read<PackingProvider>();
      await packingProvider.loadBagsFromServer(
        tripId: widget.tripId!,
        deviceUuid: widget.deviceUuid!,
        deviceToken: widget.deviceToken!,
      );

      if (!mounted) return;

      // 3. 성공: 화면 닫고 성공 메시지 표시
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이템이 짐 리스트에 추가되었습니다.')),
      );
    } catch (e) {
      // 에러 처리
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('아이템 저장에 실패했어요: $e')),
      );
    } finally {
      // 저장 상태 해제
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

// ============================================================
// 내부 위젯들
// ============================================================

/// 작은 칩 위젯
/// 아이템의 관련 라벨들을 작은 태그 형태로 표시합니다.
class _SmallChip extends StatelessWidget {
  final String text;
  const _SmallChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999), // 완전히 둥근 모서리
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }
}

/// 상태 카드 위젯
/// 기내 수하물 또는 위탁 수하물의 허용 여부를 표시하는 카드입니다.
/// StatusStyle에 따라 색상, 아이콘이 달라집니다 (허용=초록, 불가=빨강 등).
class _StatusCard extends StatelessWidget {
  final String label;        // "기내 수하물" 또는 "위탁 수하물"
  final String statusLabel;  // "허용", "제한", "불가" 등
  final String shortReason;  // 간단한 이유 설명
  final StatusStyle style;   // 색상, 아이콘 등 스타일 정보

  const _StatusCard({
    required this.label,
    required this.statusLabel,
    required this.shortReason,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: style.bg, // 배경색 (허용=연한 초록, 불가=연한 빨강 등)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 라벨
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: style.text.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          // 상태 라벨 + 아이콘
          Row(
            children: [
              Icon(style.icon, size: 16, color: style.text), // 체크/엑스 아이콘
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: style.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 간단한 이유 설명
          Text(
            shortReason,
            style: TextStyle(
              fontSize: 11,
              color: style.text.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
