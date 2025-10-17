import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Camera, CheckCircle, MapPin, Plane } from "lucide-react"
import Link from "next/link"

export function Hero() {
  return (
    <section className="container px-4 py-12">
      <div className="text-center space-y-6 mb-12">
        <h1 className="text-4xl font-bold tracking-tight text-balance">Cherry-pick your trip!</h1>
        <p className="text-xl text-muted-foreground text-balance max-w-2xl mx-auto">
          AI 기반 항공 규정 체크와 스마트한 여행 짐 관리로 완벽한 여행을 준비하세요
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Link href="/scan">
            <Button size="lg" className="text-lg px-8">
              <Camera className="mr-2 h-5 w-5" />짐 스캔하기
            </Button>
          </Link>
          <Link href="/checklist">
            <Button variant="outline" size="lg" className="text-lg px-8 bg-transparent">
              <Plane className="mr-2 h-5 w-5" />
              규정 확인하기
            </Button>
          </Link>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="p-6 text-center space-y-4">
          <div className="mx-auto w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
            <Camera className="h-6 w-6 text-primary" />
          </div>
          <h3 className="font-semibold">AI 물품 인식</h3>
          <p className="text-sm text-muted-foreground">사진만 찍으면 자동으로 물품을 인식하고 규정을 확인해드려요</p>
        </Card>

        <Card className="p-6 text-center space-y-4">
          <div className="mx-auto w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
            <CheckCircle className="h-6 w-6 text-primary" />
          </div>
          <h3 className="font-semibold">규정 자동 체크</h3>
          <p className="text-sm text-muted-foreground">국가별, 항공사별 기내/위탁수하물 규정을 실시간으로 확인</p>
        </Card>

        <Card className="p-6 text-center space-y-4">
          <div className="mx-auto w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
            <MapPin className="h-6 w-6 text-primary" />
          </div>
          <h3 className="font-semibold">위치 추적</h3>
          <p className="text-sm text-muted-foreground">가방 속 물건의 위치를 기억하고 쉽게 찾을 수 있어요</p>
        </Card>

        <Card className="p-6 text-center space-y-4">
          <div className="mx-auto w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
            <Plane className="h-6 w-6 text-primary" />
          </div>
          <h3 className="font-semibold">맞춤 추천</h3>
          <p className="text-sm text-muted-foreground">여행지와 일정에 맞는 개인화된 짐 리스트를 추천해드려요</p>
        </Card>
      </div>
    </section>
  )
}
