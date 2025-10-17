"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Plane, MapPin, AlertTriangle, CheckCircle, Info, Search } from "lucide-react"

interface RegulationData {
  country: string
  airline: string
  carryOn: {
    maxWeight: string
    maxSize: string
    liquidLimit: string
    restrictions: string[]
  }
  checked: {
    maxWeight: string
    maxSize: string
    restrictions: string[]
  }
  prohibited: string[]
  dutyFree: {
    alcohol: string
    tobacco: string
    perfume: string
  }
}

export function RegulationChecker() {
  const [selectedCountry, setSelectedCountry] = useState("")
  const [selectedAirline, setSelectedAirline] = useState("")
  const [searchQuery, setSearchQuery] = useState("")
  const [regulationData, setRegulationData] = useState<RegulationData | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const countries = [
    "일본",
    "미국",
    "중국",
    "태국",
    "베트남",
    "필리핀",
    "싱가포르",
    "말레이시아",
    "인도네시아",
    "대만",
    "홍콩",
    "호주",
    "뉴질랜드",
    "영국",
    "프랑스",
    "독일",
    "이탈리아",
    "스페인",
    "캐나다",
    "브라질",
  ]

  const airlines = [
    "대한항공",
    "아시아나항공",
    "제주항공",
    "진에어",
    "티웨이항공",
    "에어부산",
    "JAL",
    "ANA",
    "유나이티드",
    "델타",
    "아메리칸항공",
    "에미레이트",
    "싱가포르항공",
    "타이항공",
    "베트남항공",
    "세부퍼시픽",
    "에어아시아",
    "캐세이퍼시픽",
  ]

  const handleSearch = async () => {
    if (!selectedCountry || !selectedAirline) return

    setIsLoading(true)

    // 실제 구현에서는 규정 데이터베이스 API 호출
    await new Promise((resolve) => setTimeout(resolve, 1500))

    // 모의 데이터
    const mockData: RegulationData = {
      country: selectedCountry,
      airline: selectedAirline,
      carryOn: {
        maxWeight: "10kg",
        maxSize: "55cm × 40cm × 20cm",
        liquidLimit: "100ml (총 1L)",
        restrictions: ["투명 지퍼백에 보관", "개별 용기 100ml 이하", "1인당 1개 지퍼백만 허용"],
      },
      checked: {
        maxWeight: "23kg",
        maxSize: "158cm (3변의 합)",
        restrictions: ["리튬배터리 금지", "인화성 물질 금지", "날카로운 물건 주의"],
      },
      prohibited: ["폭발물", "인화성 액체", "독성 물질", "방사성 물질", "부식성 물질", "자성 물질", "산화성 물질"],
      dutyFree: {
        alcohol: "1L (21도 이상 22도 미만) 또는 400ml (22도 이상)",
        tobacco: "담배 200개비 또는 시가 50개비",
        perfume: "60ml",
      },
    }

    setRegulationData(mockData)
    setIsLoading(false)
  }

  const filteredCountries = countries.filter((country) => country.toLowerCase().includes(searchQuery.toLowerCase()))

  return (
    <div className="container px-4 py-6 space-y-6">
      <div className="text-center">
        <h1 className="text-2xl font-bold">항공 규정 확인</h1>
      </div>

      <Card className="p-6 space-y-4">
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="country">목적지 국가</Label>
            <Select value={selectedCountry} onValueChange={setSelectedCountry}>
              <SelectTrigger>
                <SelectValue placeholder="국가를 선택하세요" />
              </SelectTrigger>
              <SelectContent>
                {countries.map((country) => (
                  <SelectItem key={country} value={country}>
                    {country}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="airline">항공사</Label>
            <Select value={selectedAirline} onValueChange={setSelectedAirline}>
              <SelectTrigger>
                <SelectValue placeholder="항공사를 선택하세요" />
              </SelectTrigger>
              <SelectContent>
                {airlines.map((airline) => (
                  <SelectItem key={airline} value={airline}>
                    {airline}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <Button
            onClick={handleSearch}
            className="w-full"
            disabled={!selectedCountry || !selectedAirline || isLoading}
          >
            {isLoading ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-primary-foreground border-t-transparent mr-2"></div>
                규정 확인 중...
              </>
            ) : (
              <>
                <Search className="mr-2 h-4 w-4" />
                규정 확인하기
              </>
            )}
          </Button>
        </div>
      </Card>

      {regulationData && (
        <div className="space-y-6">
          <div className="flex items-center gap-2">
            <Plane className="h-5 w-5 text-primary" />
            <h2 className="text-xl font-semibold">
              {regulationData.country} - {regulationData.airline}
            </h2>
          </div>

          <Tabs defaultValue="carry-on" className="w-full">
            <TabsList className="grid w-full grid-cols-4">
              <TabsTrigger value="carry-on">기내수하물</TabsTrigger>
              <TabsTrigger value="checked">위탁수하물</TabsTrigger>
              <TabsTrigger value="prohibited">금지품목</TabsTrigger>
              <TabsTrigger value="duty-free">면세한도</TabsTrigger>
            </TabsList>

            <TabsContent value="carry-on" className="space-y-4">
              <Card className="p-6 space-y-4">
                <div className="flex items-center gap-2">
                  <CheckCircle className="h-5 w-5 text-green-600" />
                  <h3 className="text-lg font-semibold">기내 수하물 규정</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">최대 무게</Label>
                    <div className="p-3 bg-muted rounded-lg">
                      <span className="font-semibold">{regulationData.carryOn.maxWeight}</span>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">최대 크기</Label>
                    <div className="p-3 bg-muted rounded-lg">
                      <span className="font-semibold">{regulationData.carryOn.maxSize}</span>
                    </div>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label className="text-sm font-medium">액체류 제한</Label>
                  <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <AlertTriangle className="h-4 w-4 text-amber-600" />
                      <span className="font-semibold text-amber-800">{regulationData.carryOn.liquidLimit}</span>
                    </div>
                    <ul className="space-y-1">
                      {regulationData.carryOn.restrictions.map((restriction, index) => (
                        <li key={index} className="text-sm text-amber-700 flex items-start gap-2">
                          <span className="w-1 h-1 bg-amber-600 rounded-full mt-2 flex-shrink-0"></span>
                          {restriction}
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              </Card>
            </TabsContent>

            <TabsContent value="checked" className="space-y-4">
              <Card className="p-6 space-y-4">
                <div className="flex items-center gap-2">
                  <CheckCircle className="h-5 w-5 text-blue-600" />
                  <h3 className="text-lg font-semibold">위탁 수하물 규정</h3>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">최대 무게</Label>
                    <div className="p-3 bg-muted rounded-lg">
                      <span className="font-semibold">{regulationData.checked.maxWeight}</span>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">최대 크기</Label>
                    <div className="p-3 bg-muted rounded-lg">
                      <span className="font-semibold">{regulationData.checked.maxSize}</span>
                    </div>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label className="text-sm font-medium">주의사항</Label>
                  <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
                    <ul className="space-y-1">
                      {regulationData.checked.restrictions.map((restriction, index) => (
                        <li key={index} className="text-sm text-blue-700 flex items-start gap-2">
                          <span className="w-1 h-1 bg-blue-600 rounded-full mt-2 flex-shrink-0"></span>
                          {restriction}
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              </Card>
            </TabsContent>

            <TabsContent value="prohibited" className="space-y-4">
              <Card className="p-6 space-y-4">
                <div className="flex items-center gap-2">
                  <AlertTriangle className="h-5 w-5 text-red-600" />
                  <h3 className="text-lg font-semibold">금지 품목</h3>
                </div>

                <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                  {regulationData.prohibited.map((item, index) => (
                    <Badge key={index} variant="destructive" className="justify-center py-2">
                      {item}
                    </Badge>
                  ))}
                </div>

                <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <Info className="h-4 w-4 text-red-600" />
                    <span className="font-semibold text-red-800">중요 안내</span>
                  </div>
                  <p className="text-sm text-red-700">
                    위 품목들은 기내 및 위탁 수하물 모두 반입이 금지됩니다. 자세한 사항은 해당 항공사 및 공항 보안청에
                    문의하세요.
                  </p>
                </div>
              </Card>
            </TabsContent>

            <TabsContent value="duty-free" className="space-y-4">
              <Card className="p-6 space-y-4">
                <div className="flex items-center gap-2">
                  <MapPin className="h-5 w-5 text-green-600" />
                  <h3 className="text-lg font-semibold">면세 한도</h3>
                </div>

                <div className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div className="p-4 bg-green-50 border border-green-200 rounded-lg text-center">
                      <div className="text-2xl mb-2">🍷</div>
                      <div className="font-semibold text-green-800">주류</div>
                      <div className="text-sm text-green-700 mt-1">{regulationData.dutyFree.alcohol}</div>
                    </div>
                    <div className="p-4 bg-green-50 border border-green-200 rounded-lg text-center">
                      <div className="text-2xl mb-2">🚬</div>
                      <div className="font-semibold text-green-800">담배</div>
                      <div className="text-sm text-green-700 mt-1">{regulationData.dutyFree.tobacco}</div>
                    </div>
                    <div className="p-4 bg-green-50 border border-green-200 rounded-lg text-center">
                      <div className="text-2xl mb-2">🌸</div>
                      <div className="font-semibold text-green-800">향수</div>
                      <div className="text-sm text-green-700 mt-1">{regulationData.dutyFree.perfume}</div>
                    </div>
                  </div>

                  <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Info className="h-4 w-4 text-green-600" />
                      <span className="font-semibold text-green-800">면세 한도 안내</span>
                    </div>
                    <p className="text-sm text-green-700">
                      위 한도는 성인 1인 기준이며, 국가별로 상이할 수 있습니다. 초과 시 관세가 부과될 수 있으니
                      주의하세요.
                    </p>
                  </div>
                </div>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      )}
    </div>
  )
}
