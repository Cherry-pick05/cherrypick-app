import 'package:flutter/material.dart';

class TravelRecommendations extends StatefulWidget {
  const TravelRecommendations({super.key});

  @override
  State<TravelRecommendations> createState() => _TravelRecommendationsState();
}

class _TravelRecommendationsState extends State<TravelRecommendations> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDestination = '';
  String _selectedDuration = '';
  String _travelDate = '';
  bool _isLoading = false;
  RecommendationData? _recommendations;

  final List<String> _destinations = [
    '일본 도쿄',
    '일본 오사카',
    '일본 교토',
    '태국 방콕',
    '태국 푸켓',
    '베트남 호치민',
    '베트남 하노이',
    '싱가포르',
    '말레이시아 쿠알라룸푸르',
    '필리핀 세부',
    '필리핀 보라카이',
    '대만 타이베이',
    '홍콩',
    '중국 상하이',
    '중국 베이징',
    '미국 뉴욕',
    '미국 로스앤젤레스',
    '영국 런던',
    '프랑스 파리',
    '호주 시드니',
  ];

  final List<String> _durations = [
    '1박 2일',
    '2박 3일',
    '3박 4일',
    '4박 5일',
    '5박 6일',
    '6박 7일',
    '1주일 이상',
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
              '여행 추천',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchCard(),
          if (_recommendations != null) ...[
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
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDestination.isEmpty ? null : _selectedDestination,
                  decoration: const InputDecoration(
                    labelText: '여행지',
                  ),
                  items: _destinations.map((dest) {
                    return DropdownMenuItem(
                      value: dest,
                      child: Text(dest),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDestination = value ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDuration.isEmpty ? null : _selectedDuration,
                  decoration: const InputDecoration(
                    labelText: '여행 기간',
                  ),
                  items: _durations.map((dur) {
                    return DropdownMenuItem(
                      value: dur,
                      child: Text(dur),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDuration = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: '출발 날짜',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            controller: TextEditingController(text: _travelDate),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _travelDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                });
              }
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedDestination.isNotEmpty && _selectedDuration.isNotEmpty && _travelDate.isNotEmpty && !_isLoading
                  ? _generateRecommendations
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
                        Text('추천 생성 중...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Text('맞춤 추천 받기'),
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
          Icons.location_on,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '${_recommendations!.destination} ${_recommendations!.duration} 여행',
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
            Tab(text: '날씨'),
            Tab(text: '인기 아이템'),
            Tab(text: '옷차림'),
            Tab(text: '쇼핑 가이드'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWeatherTab(),
              _buildPopularItemsTab(),
              _buildClothingTab(),
              _buildShoppingTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wb_sunny,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                '현지 날씨 정보',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.wb_sunny,
                          color: Colors.yellow,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _recommendations!.weather.condition,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '날씨 상태',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildWeatherInfo(
                            Icons.thermostat,
                            Colors.red,
                            _recommendations!.weather.temperature,
                            '기온',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildWeatherInfo(
                            Icons.water_drop,
                            Colors.blue,
                            _recommendations!.weather.humidity,
                            '습도',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현지 팁',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._recommendations!.localTips.take(3).map((tip) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildPopularItemsTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                '다른 여행자들이 많이 챙긴 아이템',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recommendations!.popularItems.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.reason,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.popularity}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '인기도',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('내 짐 리스트에 추가'),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildClothingTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                '추천 옷차림',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recommendations!.clothingRecommendations.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.essential 
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: Border.all(
                  color: item.essential 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.item,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.essential) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '필수',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.reason,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        ),
      ),
    );
  }

  Widget _buildShoppingTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                '현지 쇼핑 가이드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recommendations!.shoppingGuide.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.item,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.savings} 절약',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '현지 가격: ${item.localPrice}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '국내 가격: ${item.koreaPrice}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '쇼핑 팁',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '면세점보다 현지 매장에서 더 저렴한 경우가 많아요. 가격 비교 후 구매하세요!',
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
        ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, Color color, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _generateRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    // 실제 구현에서는 여행 데이터 API 호출
    await Future.delayed(const Duration(seconds: 2));

    // 모의 데이터
    setState(() {
      _recommendations = RecommendationData(
        destination: _selectedDestination,
        duration: _selectedDuration,
        season: "봄",
        weather: WeatherInfo(
          temperature: "15-22°C",
          condition: "맑음, 가끔 구름",
          humidity: "60-70%",
          rainfall: "낮음",
        ),
        popularItems: [
          PopularItem(
            name: "휴대용 우산",
            category: "우천용품",
            popularity: 89,
            reason: "갑작스러운 봄비 대비",
          ),
          PopularItem(
            name: "가디건",
            category: "의류",
            popularity: 92,
            reason: "일교차가 큰 봄 날씨",
          ),
          PopularItem(
            name: "편한 운동화",
            category: "신발",
            popularity: 95,
            reason: "많은 걸음과 관광",
          ),
          PopularItem(
            name: "휴대용 충전기",
            category: "전자기기",
            popularity: 88,
            reason: "사진 촬영과 지도 사용",
          ),
          PopularItem(
            name: "선크림",
            category: "화장품",
            popularity: 85,
            reason: "강한 자외선 차단",
          ),
        ],
        clothingRecommendations: [
          ClothingRecommendation(
            item: "얇은 긴팔 티셔츠",
            reason: "일교차 대비 및 자외선 차단",
            essential: true,
          ),
          ClothingRecommendation(
            item: "청바지 또는 편한 바지",
            reason: "활동성과 보온성",
            essential: true,
          ),
          ClothingRecommendation(
            item: "가벼운 재킷",
            reason: "저녁 시간 쌀쌀함 대비",
            essential: true,
          ),
          ClothingRecommendation(
            item: "편안한 운동화",
            reason: "장시간 걷기에 적합",
            essential: true,
          ),
          ClothingRecommendation(
            item: "모자",
            reason: "자외선 차단",
            essential: false,
          ),
          ClothingRecommendation(
            item: "스카프",
            reason: "패션 아이템 겸 보온",
            essential: false,
          ),
        ],
        shoppingGuide: [
          ShoppingItem(
            item: "화장품 (스킨케어)",
            localPrice: "¥2,000-5,000",
            koreaPrice: "30,000-80,000원",
            savings: "최대 40%",
            category: "뷰티",
          ),
          ShoppingItem(
            item: "전자제품 (카메라)",
            localPrice: "¥50,000-100,000",
            koreaPrice: "800,000-1,500,000원",
            savings: "최대 25%",
            category: "전자기기",
          ),
          ShoppingItem(
            item: "의류 (유니클로)",
            localPrice: "¥1,000-3,000",
            koreaPrice: "20,000-50,000원",
            savings: "최대 30%",
            category: "패션",
          ),
          ShoppingItem(
            item: "과자/간식",
            localPrice: "¥100-500",
            koreaPrice: "2,000-8,000원",
            savings: "최대 50%",
            category: "식품",
          ),
        ],
        localTips: [
          "대부분의 숙소에서 드라이어를 제공하므로 별도로 챙기지 않아도 됩니다",
          "편의점에서 우산을 저렴하게 구매할 수 있어요",
          "현지 약국에서 기본 의약품을 쉽게 구할 수 있습니다",
          "대중교통 이용 시 IC카드를 미리 준비하면 편리해요",
          "현금 사용이 많으니 충분한 현금을 준비하세요",
        ],
      );
      _isLoading = false;
    });
  }
}

class RecommendationData {
  final String destination;
  final String duration;
  final String season;
  final WeatherInfo weather;
  final List<PopularItem> popularItems;
  final List<ClothingRecommendation> clothingRecommendations;
  final List<ShoppingItem> shoppingGuide;
  final List<String> localTips;

  RecommendationData({
    required this.destination,
    required this.duration,
    required this.season,
    required this.weather,
    required this.popularItems,
    required this.clothingRecommendations,
    required this.shoppingGuide,
    required this.localTips,
  });
}

class WeatherInfo {
  final String temperature;
  final String condition;
  final String humidity;
  final String rainfall;

  WeatherInfo({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.rainfall,
  });
}

class PopularItem {
  final String name;
  final String category;
  final int popularity;
  final String reason;

  PopularItem({
    required this.name,
    required this.category,
    required this.popularity,
    required this.reason,
  });
}

class ClothingRecommendation {
  final String item;
  final String reason;
  final bool essential;

  ClothingRecommendation({
    required this.item,
    required this.reason,
    required this.essential,
  });
}

class ShoppingItem {
  final String item;
  final String localPrice;
  final String koreaPrice;
  final String savings;
  final String category;

  ShoppingItem({
    required this.item,
    required this.localPrice,
    required this.koreaPrice,
    required this.savings,
    required this.category,
  });
}
