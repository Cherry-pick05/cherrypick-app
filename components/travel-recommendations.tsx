"use client"

import type React from "react"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import {
  MapPin,
  CloudSun,
  ShoppingBag,
  TrendingUp,
  Star,
  Users,
  Thermometer,
  Droplets,
  Sun,
  Search,
  Plus,
} from "lucide-react"

interface WeatherInfo {
  temperature: string
  condition: string
  humidity: string
  rainfall: string
  icon: React.ReactNode
}

interface RecommendationData {
  destination: string
  duration: string
  season: string
  weather: WeatherInfo
  popularItems: Array<{
    name: string
    category: string
    popularity: number
    reason: string
  }>
  clothingRecommendations: Array<{
    item: string
    reason: string
    essential: boolean
  }>
  shoppingGuide: Array<{
    item: string
    localPrice: string
    koreaPrice: string
    savings: string
    category: string
  }>
  localTips: string[]
}

export function TravelRecommendations() {
  const [destination, setDestination] = useState("")
  const [duration, setDuration] = useState("")
  const [travelDate, setTravelDate] = useState("")
  const [recommendations, setRecommendations] = useState<RecommendationData | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const destinations = [
    "일본 도쿄",
    "일본 오사카",
    "일본 교토",
    "태국 방콕",
    "태국 푸켓",
    "베트남 호치민",
    "베트남 하노이",
    "싱가포르",
    "말레이시아 쿠알라룸푸르",
    "필리핀 세부",
    "필리핀 보라카이",
    "대만 타이베이",
    "홍콩",
    "중국 상하이",
    "중국 베이징",
    "미국 뉴욕",
    "미국 로스앤젤레스",
    "영국 런던",
    "프랑스 파리",
    "호주 시드니",
  ]

  const durations = ["1박 2일", "2박 3일", "3박 4일", "4박 5일", "5박 6일", "6박 7일", "1주일 이상"]

  const generateRecommendations = async () => {
    if (!destination || !duration || !travelDate) return

    setIsLoading(true)

    // 실제 구현에서는 여행 데이터 API 호출
    await new Promise((resolve) => setTimeout(resolve, 2000))

    // 모의 데이터
    const mockData: RecommendationData = {
      destination,
      duration,
      season: "봄",
      weather: {
        temperature: "15-22°C",
        condition: "맑음, 가끔 구름",
        humidity: "60-70%",
        rainfall: "낮음",
        icon: <Sun className="h-6 w-6 text-yellow-500" />,
      },
      popularItems: [
        { name: "휴대용 우산", category: "우천용품", popularity: 89, reason: "갑작스러운 봄비 대비" },
        { name: "가디건", category: "의류", popularity: 92, reason: "일교차가 큰 봄 날씨" },
        { name: "편한 운동화", category: "신발", popularity: 95, reason: "많은 걸음과 관광" },
        { name: "휴대용 충전기", category: "전자기기", popularity: 88, reason: "사진 촬영과 지도 사용" },
        { name: "선크림", category: "화장품", popularity: 85, reason: "강한 자외선 차단" },
      ],
      clothingRecommendations: [
        { item: "얇은 긴팔 티셔츠", reason: "일교차 대비 및 자외선 차단", essential: true },
        { item: "청바지 또는 편한 바지", reason: "활동성과 보온성", essential: true },
        { item: "가벼운 재킷", reason: "저녁 시간 쌀쌀함 대비", essential: true },
        { item: "편안한 운동화", reason: "장시간 걷기에 적합", essential: true },
        { item: "모자", reason: "자외선 차단", essential: false },
        { item: "스카프", reason: "패션 아이템 겸 보온", essential: false },
      ],
      shoppingGuide: [
        {
          item: "화장품 (스킨케어)",
          localPrice: "¥2,000-5,000",
          koreaPrice: "30,000-80,000원",
          savings: "최대 40%",
          category: "뷰티",
        },
        {
          item: "전자제품 (카메라)",
          localPrice: "¥50,000-100,000",
          koreaPrice: "800,000-1,500,000원",
          savings: "최대 25%",
          category: "전자기기",
        },
        {
          item: "의류 (유니클로)",
          localPrice: "¥1,000-3,000",
          koreaPrice: "20,000-50,000원",
          savings: "최대 30%",
          category: "패션",
        },
        {
          item: "과자/간식",
          localPrice: "¥100-500",
          koreaPrice: "2,000-8,000원",
          savings: "최대 50%",
          category: "식품",
        },
      ],
      localTips: [
        "대부분의 숙소에서 드라이어를 제공하므로 별도로 챙기지 않아도 됩니다",
        "편의점에서 우산을 저렴하게 구매할 수 있어요",
        "현지 약국에서 기본 의약품을 쉽게 구할 수 있습니다",
        "대중교통 이용 시 IC카드를 미리 준비하면 편리해요",
        "현금 사용이 많으니 충분한 현금을 준비하세요",
      ],
    }

    setRecommendations(mockData)
    setIsLoading(false)
  }

  return (
    <div className="container px-4 py-6 space-y-6">
      <div className="text-center">
        <h1 className="text-2xl font-bold">여행 추천</h1>
      </div>

      <Card className="p-6 space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="space-y-2">
            <Label htmlFor="destination">여행지</Label>
            <Select value={destination} onValueChange={setDestination}>
              <SelectTrigger>
                <SelectValue placeholder="목적지 선택" />
              </SelectTrigger>
              <SelectContent>
                {destinations.map((dest) => (
                  <SelectItem key={dest} value={dest}>
                    {dest}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="duration">여행 기간</Label>
            <Select value={duration} onValueChange={setDuration}>
              <SelectTrigger>
                <SelectValue placeholder="기간 선택" />
              </SelectTrigger>
              <SelectContent>
                {durations.map((dur) => (
                  <SelectItem key={dur} value={dur}>
                    {dur}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="travel-date">출발 날짜</Label>
            <Input id="travel-date" type="date" value={travelDate} onChange={(e) => setTravelDate(e.target.value)} />
          </div>
        </div>

        <Button
          onClick={generateRecommendations}
          className="w-full"
          disabled={!destination || !duration || !travelDate || isLoading}
        >
          {isLoading ? (
            <>
              <div className="animate-spin rounded-full h-4 w-4 border-2 border-primary-foreground border-t-transparent mr-2"></div>
              추천 생성 중...
            </>
          ) : (
            <>
              <Search className="mr-2 h-4 w-4" />
              맞춤 추천 받기
            </>
          )}
        </Button>
      </Card>

      {recommendations && (
        <div className="space-y-6">
          <div className="flex items-center gap-2">
            <MapPin className="h-5 w-5 text-primary" />
            <h2 className="text-xl font-semibold">
              {recommendations.destination} {recommendations.duration} 여행
            </h2>
          </div>

          <Tabs defaultValue="weather" className="w-full">
            <TabsList className="grid w-full grid-cols-4">
              <TabsTrigger value="weather">날씨</TabsTrigger>
              <TabsTrigger value="popular">인기 아이템</TabsTrigger>
              <TabsTrigger value="clothing">옷차림</TabsTrigger>
              <TabsTrigger value="shopping">쇼핑 가이드</TabsTrigger>
            </TabsList>

            <TabsContent value="weather" className="space-y-4">
              <Card className="p-6">
                <div className="flex items-center gap-2 mb-4">
                  <CloudSun className="h-5 w-5 text-primary" />
                  <h3 className="text-lg font-semibold">현지 날씨 정보</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <div className="flex items-center gap-3">
                      {recommendations.weather.icon}
                      <div>
                        <div className="font-semibold">{recommendations.weather.condition}</div>
                        <div className="text-sm text-muted-foreground">날씨 상태</div>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div className="flex items-center gap-2">
                        <Thermometer className="h-4 w-4 text-red-500" />
                        <div>
                          <div className="font-semibold">{recommendations.weather.temperature}</div>
                          <div className="text-xs text-muted-foreground">기온</div>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <Droplets className="h-4 w-4 text-blue-500" />
                        <div>
                          <div className="font-semibold">{recommendations.weather.humidity}</div>
                          <div className="text-xs text-muted-foreground">습도</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-3">
                    <h4 className="font-semibold">현지 팁</h4>
                    <ul className="space-y-2">
                      {recommendations.localTips.slice(0, 3).map((tip, index) => (
                        <li key={index} className="text-sm text-muted-foreground flex items-start gap-2">
                          <span className="w-1 h-1 bg-primary rounded-full mt-2 flex-shrink-0"></span>
                          {tip}
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              </Card>
            </TabsContent>

            <TabsContent value="popular" className="space-y-4">
              <Card className="p-6">
                <div className="flex items-center gap-2 mb-4">
                  <TrendingUp className="h-5 w-5 text-primary" />
                  <h3 className="text-lg font-semibold">다른 여행자들이 많이 챙긴 아이템</h3>
                </div>

                <div className="space-y-3">
                  {recommendations.popularItems.map((item, index) => (
                    <Card key={index} className="p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-semibold">{item.name}</span>
                            <Badge variant="secondary">{item.category}</Badge>
                          </div>
                          <p className="text-sm text-muted-foreground">{item.reason}</p>
                        </div>
                        <div className="text-right">
                          <div className="flex items-center gap-1">
                            <Star className="h-4 w-4 text-yellow-500" />
                            <span className="font-semibold">{item.popularity}%</span>
                          </div>
                          <div className="text-xs text-muted-foreground">인기도</div>
                        </div>
                      </div>
                    </Card>
                  ))}
                </div>

                <Button className="w-full mt-4">
                  <Plus className="mr-2 h-4 w-4" />내 짐 리스트에 추가
                </Button>
              </Card>
            </TabsContent>

            <TabsContent value="clothing" className="space-y-4">
              <Card className="p-6">
                <div className="flex items-center gap-2 mb-4">
                  <Users className="h-5 w-5 text-primary" />
                  <h3 className="text-lg font-semibold">추천 옷차림</h3>
                </div>

                <div className="space-y-3">
                  {recommendations.clothingRecommendations.map((item, index) => (
                    <div
                      key={index}
                      className={`p-4 rounded-lg border ${
                        item.essential ? "bg-primary/5 border-primary/20" : "bg-muted/50"
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <span className="font-semibold">{item.item}</span>
                            {item.essential && <Badge variant="default">필수</Badge>}
                          </div>
                          <p className="text-sm text-muted-foreground mt-1">{item.reason}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </Card>
            </TabsContent>

            <TabsContent value="shopping" className="space-y-4">
              <Card className="p-6">
                <div className="flex items-center gap-2 mb-4">
                  <ShoppingBag className="h-5 w-5 text-primary" />
                  <h3 className="text-lg font-semibold">현지 쇼핑 가이드</h3>
                </div>

                <div className="space-y-3">
                  {recommendations.shoppingGuide.map((item, index) => (
                    <Card key={index} className="p-4">
                      <div className="space-y-2">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <span className="font-semibold">{item.item}</span>
                            <Badge variant="outline">{item.category}</Badge>
                          </div>
                          <Badge variant="default" className="bg-green-600">
                            {item.savings} 절약
                          </Badge>
                        </div>
                        <div className="grid grid-cols-2 gap-4 text-sm">
                          <div>
                            <span className="text-muted-foreground">현지 가격: </span>
                            <span className="font-semibold">{item.localPrice}</span>
                          </div>
                          <div>
                            <span className="text-muted-foreground">국내 가격: </span>
                            <span className="font-semibold">{item.koreaPrice}</span>
                          </div>
                        </div>
                      </div>
                    </Card>
                  ))}
                </div>

                <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <ShoppingBag className="h-4 w-4 text-green-600" />
                    <span className="font-semibold text-green-800">쇼핑 팁</span>
                  </div>
                  <p className="text-sm text-green-700">
                    면세점보다 현지 매장에서 더 저렴한 경우가 많아요. 가격 비교 후 구매하세요!
                  </p>
                </div>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      )}
    </div>
  )
}
