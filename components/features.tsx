import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Scan, Shield, Package, MapPin, CloudSun, ShoppingBag, ArrowRight } from "lucide-react"

export function Features() {
  const features = [
    {
      icon: Scan,
      title: "스마트 스캔",
      description: "물건 사진을 찍으면 OCR로 용량을 자동 인식하고 항공 규정을 체크해드려요",
      badge: "AI 기반",
      color: "bg-blue-500/10 text-blue-600",
    },
    {
      icon: Shield,
      title: "규정 체크",
      description: "국가별, 항공사별 기내/위탁수하물 규정을 실시간으로 확인하고 위반 방지",
      badge: "실시간",
      color: "bg-green-500/10 text-green-600",
    },
    {
      icon: Package,
      title: "가방별 관리",
      description: "캐리어, 더플백 등 가방별로 짐을 효율적으로 배치하고 관리",
      badge: "최적화",
      color: "bg-purple-500/10 text-purple-600",
    },
    {
      icon: MapPin,
      title: "위치 추적",
      description: "물건이 어느 가방 어디에 있는지 사진으로 기록하고 쉽게 찾기",
      badge: "편리함",
      color: "bg-orange-500/10 text-orange-600",
    },
    {
      icon: CloudSun,
      title: "날씨 기반 추천",
      description: "여행지 날씨를 고려한 옷차림과 필수 아이템을 추천",
      badge: "맞춤형",
      color: "bg-yellow-500/10 text-yellow-600",
    },
    {
      icon: ShoppingBag,
      title: "쇼핑 가이드",
      description: "국가별 저렴한 물건과 면세점 정보로 합리적인 쇼핑 지원",
      badge: "절약",
      color: "bg-red-500/10 text-red-600",
    },
  ]

  return (
    <section className="container px-4 py-16">
      <div className="text-center space-y-4 mb-12">
        <h2 className="text-3xl font-bold">완벽한 여행 준비의 모든 것</h2>
        <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
          AI 기술과 빅데이터를 활용해 여행 준비부터 현지 생활까지 모든 것을 도와드립니다
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
        {features.map((feature, index) => (
          <Card key={index} className="p-6 space-y-4 hover:shadow-lg transition-shadow">
            <div className="flex items-center justify-between">
              <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${feature.color}`}>
                <feature.icon className="h-6 w-6" />
              </div>
              <Badge variant="secondary">{feature.badge}</Badge>
            </div>
            <div className="space-y-2">
              <h3 className="text-xl font-semibold">{feature.title}</h3>
              <p className="text-muted-foreground leading-relaxed">{feature.description}</p>
            </div>
            <Button variant="ghost" className="w-full justify-between group">
              자세히 보기
              <ArrowRight className="h-4 w-4 group-hover:translate-x-1 transition-transform" />
            </Button>
          </Card>
        ))}
      </div>

      <div className="text-center">
        <Button size="lg" className="text-lg px-8">
          지금 시작하기
          <ArrowRight className="ml-2 h-5 w-5" />
        </Button>
      </div>
    </section>
  )
}
