"use client"

import { Header } from "@/components/header"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import { Input } from "@/components/ui/input"
import { Switch } from "@/components/ui/switch"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Separator } from "@/components/ui/separator"
import { User, Bell, Globe, Scale, Plane, Download, Upload, Info, ChevronRight, LogOut } from "lucide-react"
import { useState } from "react"

export default function SettingsPage() {
  const [notifications, setNotifications] = useState({
    departure: true,
    packing: true,
    weather: false,
  })

  return (
    <div className="min-h-screen bg-background">
      <Header />

      <main className="container px-4 py-6 pb-24">
        <h1 className="text-2xl font-bold mb-6">설정</h1>

        {/* 프로필 섹션 */}
        <Card className="p-6 mb-4">
          <div className="flex items-center gap-3 mb-4">
            <User className="h-5 w-5 text-primary" />
            <h2 className="text-lg font-semibold">프로필</h2>
          </div>
          <div className="space-y-4">
            <div>
              <Label htmlFor="name">이름</Label>
              <Input id="name" placeholder="홍길동" className="mt-1.5" />
            </div>
            <div>
              <Label htmlFor="email">이메일</Label>
              <Input id="email" type="email" placeholder="example@email.com" className="mt-1.5" />
            </div>
          </div>
        </Card>

        {/* 여행 기본 설정 */}
        <Card className="p-6 mb-4">
          <div className="flex items-center gap-3 mb-4">
            <Plane className="h-5 w-5 text-primary" />
            <h2 className="text-lg font-semibold">여행 기본 설정</h2>
          </div>
          <div className="space-y-4">
            <div>
              <Label htmlFor="airline">선호 항공사</Label>
              <Select defaultValue="all">
                <SelectTrigger id="airline" className="mt-1.5">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">선택 안함</SelectItem>
                  <SelectItem value="ke">대한항공</SelectItem>
                  <SelectItem value="oz">아시아나항공</SelectItem>
                  <SelectItem value="7c">제주항공</SelectItem>
                  <SelectItem value="tw">티웨이항공</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label htmlFor="country">자주 가는 국가</Label>
              <Select defaultValue="all">
                <SelectTrigger id="country" className="mt-1.5">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">선택 안함</SelectItem>
                  <SelectItem value="jp">일본</SelectItem>
                  <SelectItem value="us">미국</SelectItem>
                  <SelectItem value="th">태국</SelectItem>
                  <SelectItem value="vn">베트남</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </Card>

        {/* 알림 설정 */}
        <Card className="p-6 mb-4">
          <div className="flex items-center gap-3 mb-4">
            <Bell className="h-5 w-5 text-primary" />
            <h2 className="text-lg font-semibold">알림 설정</h2>
          </div>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">출발 전 리마인더</p>
                <p className="text-sm text-muted-foreground">출발 1일 전 알림</p>
              </div>
              <Switch
                checked={notifications.departure}
                onCheckedChange={(checked) => setNotifications({ ...notifications, departure: checked })}
              />
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">짐 체크 알림</p>
                <p className="text-sm text-muted-foreground">미완료 항목 알림</p>
              </div>
              <Switch
                checked={notifications.packing}
                onCheckedChange={(checked) => setNotifications({ ...notifications, packing: checked })}
              />
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">날씨 변경 알림</p>
                <p className="text-sm text-muted-foreground">목적지 날씨 변화 시</p>
              </div>
              <Switch
                checked={notifications.weather}
                onCheckedChange={(checked) => setNotifications({ ...notifications, weather: checked })}
              />
            </div>
          </div>
        </Card>

        {/* 단위 설정 */}
        <Card className="p-6 mb-4">
          <div className="flex items-center gap-3 mb-4">
            <Scale className="h-5 w-5 text-primary" />
            <h2 className="text-lg font-semibold">단위 설정</h2>
          </div>
          <div className="space-y-4">
            <div>
              <Label htmlFor="weight">무게 단위</Label>
              <Select defaultValue="kg">
                <SelectTrigger id="weight" className="mt-1.5">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="kg">킬로그램 (kg)</SelectItem>
                  <SelectItem value="lbs">파운드 (lbs)</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label htmlFor="temp">온도 단위</Label>
              <Select defaultValue="celsius">
                <SelectTrigger id="temp" className="mt-1.5">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="celsius">섭씨 (°C)</SelectItem>
                  <SelectItem value="fahrenheit">화씨 (°F)</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </Card>

        {/* 언어 설정 */}
        <Card className="p-6 mb-4">
          <div className="flex items-center gap-3 mb-4">
            <Globe className="h-5 w-5 text-primary" />
            <h2 className="text-lg font-semibold">언어</h2>
          </div>
          <Select defaultValue="ko">
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="ko">한국어</SelectItem>
              <SelectItem value="en">English</SelectItem>
              <SelectItem value="ja">日本語</SelectItem>
            </SelectContent>
          </Select>
        </Card>

        {/* 데이터 관리 */}
        <Card className="p-6 mb-4">
          <div className="space-y-3">
            <button className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-accent transition-colors">
              <div className="flex items-center gap-3">
                <Download className="h-5 w-5 text-muted-foreground" />
                <span className="font-medium">데이터 백업</span>
              </div>
              <ChevronRight className="h-5 w-5 text-muted-foreground" />
            </button>
            <Separator />
            <button className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-accent transition-colors">
              <div className="flex items-center gap-3">
                <Upload className="h-5 w-5 text-muted-foreground" />
                <span className="font-medium">데이터 복원</span>
              </div>
              <ChevronRight className="h-5 w-5 text-muted-foreground" />
            </button>
          </div>
        </Card>

        {/* 앱 정보 */}
        <Card className="p-6 mb-4">
          <div className="space-y-3">
            <button className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-accent transition-colors">
              <div className="flex items-center gap-3">
                <Info className="h-5 w-5 text-muted-foreground" />
                <span className="font-medium">앱 정보</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">v1.0.0</span>
                <ChevronRight className="h-5 w-5 text-muted-foreground" />
              </div>
            </button>
            <Separator />
            <button className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-accent transition-colors">
              <span className="font-medium">이용약관</span>
              <ChevronRight className="h-5 w-5 text-muted-foreground" />
            </button>
            <Separator />
            <button className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-accent transition-colors">
              <span className="font-medium">개인정보처리방침</span>
              <ChevronRight className="h-5 w-5 text-muted-foreground" />
            </button>
          </div>
        </Card>

        {/* 로그아웃 */}
        <Button
          variant="outline"
          className="w-full text-destructive hover:text-destructive hover:bg-destructive/10 bg-transparent"
        >
          <LogOut className="h-4 w-4 mr-2" />
          로그아웃
        </Button>
      </main>
    </div>
  )
}
