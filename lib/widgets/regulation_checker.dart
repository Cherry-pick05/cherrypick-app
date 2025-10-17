import 'package:flutter/material.dart';

class RegulationChecker extends StatefulWidget {
  const RegulationChecker({super.key});

  @override
  State<RegulationChecker> createState() => _RegulationCheckerState();
}

class _RegulationCheckerState extends State<RegulationChecker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCountry = '';
  String _selectedAirline = '';
  bool _isLoading = false;
  RegulationData? _regulationData;

  final List<String> _countries = [
    '일본',
    '미국',
    '중국',
    '태국',
    '베트남',
    '필리핀',
    '싱가포르',
    '말레이시아',
    '인도네시아',
    '대만',
    '홍콩',
    '호주',
    '뉴질랜드',
    '영국',
    '프랑스',
    '독일',
    '이탈리아',
    '스페인',
    '캐나다',
    '브라질',
  ];

  final List<String> _airlines = [
    '대한항공',
    '아시아나항공',
    '제주항공',
    '진에어',
    '티웨이항공',
    '에어부산',
    'JAL',
    'ANA',
    '유나이티드',
    '델타',
    '아메리칸항공',
    '에미레이트',
    '싱가포르항공',
    '타이항공',
    '베트남항공',
    '세부퍼시픽',
    '에어아시아',
    '캐세이퍼시픽',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
              '항공 규정 확인',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchCard(),
          if (_regulationData != null) ...[
            const SizedBox(height: 24),
            _buildResultHeader(),
            const SizedBox(height: 16),
            _buildTabView(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedCountry.isEmpty ? null : _selectedCountry,
            decoration: const InputDecoration(
              labelText: '목적지 국가',
            ),
            items: _countries.map((country) {
              return DropdownMenuItem(
                value: country,
                child: Text(country),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value ?? '';
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedAirline.isEmpty ? null : _selectedAirline,
            decoration: const InputDecoration(
              labelText: '항공사',
            ),
            items: _airlines.map((airline) {
              return DropdownMenuItem(
                value: airline,
                child: Text(airline),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAirline = value ?? '';
              });
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedCountry.isNotEmpty && _selectedAirline.isNotEmpty && !_isLoading
                  ? _searchRegulations
                  : null,
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('규정 확인 중...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Text('규정 확인하기'),
                      ],
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return Row(
      children: [
        Icon(
          Icons.flight,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '${_regulationData!.country} - ${_regulationData!.airline}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTabView() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '기내수하물'),
            Tab(text: '위탁수하물'),
            Tab(text: '금지품목'),
            Tab(text: '면세한도'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCarryOnTab(),
              _buildCheckedTab(),
              _buildProhibitedTab(),
              _buildDutyFreeTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarryOnTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text(
                '기내 수하물 규정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  '최대 무게',
                  _regulationData!.carryOn.maxWeight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  '최대 크기',
                  _regulationData!.carryOn.maxSize,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLiquidRestrictions(),
        ],
        ),
      ),
    );
  }

  Widget _buildCheckedTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              Text(
                '위탁 수하물 규정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  '최대 무게',
                  _regulationData!.checked.maxWeight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  '최대 크기',
                  _regulationData!.checked.maxSize,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCheckedRestrictions(),
        ],
        ),
      ),
    );
  }

  Widget _buildProhibitedTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                '금지 품목',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _regulationData!.prohibited.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '중요 안내',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '위 품목들은 기내 및 위탁 수하물 모두 반입이 금지됩니다. 자세한 사항은 해당 항공사 및 공항 보안청에 문의하세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildDutyFreeTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text(
                '면세 한도',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDutyFreeItem('🍷', '주류', _regulationData!.dutyFree.alcohol),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDutyFreeItem('🚬', '담배', _regulationData!.dutyFree.tobacco),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDutyFreeItem('🌸', '향수', _regulationData!.dutyFree.perfume),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '면세 한도 안내',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '위 한도는 성인 1인 기준이며, 국가별로 상이할 수 있습니다. 초과 시 관세가 부과될 수 있으니 주의하세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidRestrictions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '액체류 제한',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.amber.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _regulationData!.carryOn.liquidLimit,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._regulationData!.carryOn.restrictions.map((restriction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          restriction,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckedRestrictions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주의사항',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._regulationData!.checked.restrictions.map((restriction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          restriction,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDutyFreeItem(String emoji, String title, String limit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            limit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _searchRegulations() async {
    setState(() {
      _isLoading = true;
    });

    // 실제 구현에서는 규정 데이터베이스 API 호출
    await Future.delayed(const Duration(seconds: 1));

    // 모의 데이터
    setState(() {
      _regulationData = RegulationData(
        country: _selectedCountry,
        airline: _selectedAirline,
        carryOn: CarryOnData(
          maxWeight: "10kg",
          maxSize: "55cm × 40cm × 20cm",
          liquidLimit: "100ml (총 1L)",
          restrictions: ["투명 지퍼백에 보관", "개별 용기 100ml 이하", "1인당 1개 지퍼백만 허용"],
        ),
        checked: CheckedData(
          maxWeight: "23kg",
          maxSize: "158cm (3변의 합)",
          restrictions: ["리튬배터리 금지", "인화성 물질 금지", "날카로운 물건 주의"],
        ),
        prohibited: ["폭발물", "인화성 액체", "독성 물질", "방사성 물질", "부식성 물질", "자성 물질", "산화성 물질"],
        dutyFree: DutyFreeData(
          alcohol: "1L (21도 이상 22도 미만) 또는 400ml (22도 이상)",
          tobacco: "담배 200개비 또는 시가 50개비",
          perfume: "60ml",
        ),
      );
      _isLoading = false;
    });
  }
}

class RegulationData {
  final String country;
  final String airline;
  final CarryOnData carryOn;
  final CheckedData checked;
  final List<String> prohibited;
  final DutyFreeData dutyFree;

  RegulationData({
    required this.country,
    required this.airline,
    required this.carryOn,
    required this.checked,
    required this.prohibited,
    required this.dutyFree,
  });
}

class CarryOnData {
  final String maxWeight;
  final String maxSize;
  final String liquidLimit;
  final List<String> restrictions;

  CarryOnData({
    required this.maxWeight,
    required this.maxSize,
    required this.liquidLimit,
    required this.restrictions,
  });
}

class CheckedData {
  final String maxWeight;
  final String maxSize;
  final List<String> restrictions;

  CheckedData({
    required this.maxWeight,
    required this.maxSize,
    required this.restrictions,
  });
}

class DutyFreeData {
  final String alcohol;
  final String tobacco;
  final String perfume;

  DutyFreeData({
    required this.alcohol,
    required this.tobacco,
    required this.perfume,
  });
}
