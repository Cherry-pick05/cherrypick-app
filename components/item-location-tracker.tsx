"use client"

import type React from "react"

import { useState, useRef } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Camera, Search, MapPin, Package, Plus, X, Trash2 } from "lucide-react"

interface ItemLocation {
  id: string
  itemName: string
  bagName: string
  location: string
  photo?: string
  timestamp: string
  notes?: string
}

export function ItemLocationTracker() {
  const [locations, setLocations] = useState<ItemLocation[]>([
    {
      id: "1",
      itemName: "여권",
      bagName: "기내용 캐리어",
      location: "앞주머니",
      photo: "/passport-in-luggage-pocket.jpg",
      timestamp: "2024-01-15 14:30",
      notes: "지퍼 안쪽 포켓에 보관",
    },
    {
      id: "2",
      itemName: "충전기",
      bagName: "백팩",
      location: "메인칸",
      photo: "/phone-charger-in-backpack.jpg",
      timestamp: "2024-01-15 14:25",
      notes: "노트북 옆에 위치",
    },
    {
      id: "3",
      itemName: "화장품",
      bagName: "기내용 캐리어",
      location: "투명 지퍼백",
      photo: "/cosmetics-in-clear-bag.jpg",
      timestamp: "2024-01-15 14:20",
      notes: "액체류 규정 준수",
    },
  ])

  const [searchQuery, setSearchQuery] = useState("")
  const [selectedBag, setSelectedBag] = useState("all") // Updated default value
  const [isAddingLocation, setIsAddingLocation] = useState(false)
  const [newLocation, setNewLocation] = useState({
    itemName: "",
    bagName: "",
    location: "",
    notes: "",
  })
  const [capturedPhoto, setCapturedPhoto] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const bags = ["기내용 캐리어", "위탁용 캐리어", "백팩", "더플백", "핸드백"]
  const commonLocations = ["메인칸", "앞주머니", "옆주머니", "지퍼백", "신발칸", "노트북칸", "내부포켓"]

  const filteredLocations = locations.filter((location) => {
    const matchesSearch = location.itemName.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesBag = selectedBag === "all" || location.bagName === selectedBag
    return matchesSearch && matchesBag
  })

  const handlePhotoUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        setCapturedPhoto(e.target?.result as string)
      }
      reader.readAsDataURL(file)
    }
  }

  const addNewLocation = () => {
    if (!newLocation.itemName || !newLocation.bagName || !newLocation.location) return

    const newItem: ItemLocation = {
      id: Date.now().toString(),
      itemName: newLocation.itemName,
      bagName: newLocation.bagName,
      location: newLocation.location,
      photo: capturedPhoto || undefined,
      timestamp: new Date().toLocaleString("ko-KR"),
      notes: newLocation.notes,
    }

    setLocations([newItem, ...locations])
    setNewLocation({ itemName: "", bagName: "", location: "", notes: "" })
    setCapturedPhoto(null)
    setIsAddingLocation(false)
  }

  const removeLocation = (id: string) => {
    setLocations(locations.filter((location) => location.id !== id))
  }

  const groupedLocations = filteredLocations.reduce(
    (acc, location) => {
      if (!acc[location.bagName]) {
        acc[location.bagName] = []
      }
      acc[location.bagName].push(location)
      return acc
    },
    {} as Record<string, ItemLocation[]>,
  )

  return (
    <div className="container px-4 py-6 space-y-6">
      <div className="text-center">
        <h1 className="text-2xl font-bold">물건 위치 추적</h1>
      </div>

      <Card className="p-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="물건 이름으로 검색..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
      </Card>

      {/* 검색 및 필터 */}
      <Card className="p-4 space-y-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <Select value={selectedBag} onValueChange={setSelectedBag}>
              <SelectTrigger className="w-full sm:w-48">
                <SelectValue placeholder="가방 선택" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">모든 가방</SelectItem>
                {bags.map((bag) => (
                  <SelectItem key={bag} value={bag}>
                    {bag}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        <Dialog open={isAddingLocation} onOpenChange={setIsAddingLocation}>
          <DialogTrigger asChild>
            <Button className="w-full">
              <Plus className="mr-2 h-4 w-4" />새 위치 기록
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle>물건 위치 기록</DialogTitle>
            </DialogHeader>
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="item-name">물건 이름</Label>
                <Input
                  id="item-name"
                  value={newLocation.itemName}
                  onChange={(e) => setNewLocation({ ...newLocation, itemName: e.target.value })}
                  placeholder="예: 여권, 충전기, 화장품"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="bag-name">가방</Label>
                <Select
                  value={newLocation.bagName}
                  onValueChange={(value) => setNewLocation({ ...newLocation, bagName: value })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="가방 선택" />
                  </SelectTrigger>
                  <SelectContent>
                    {bags.map((bag) => (
                      <SelectItem key={bag} value={bag}>
                        {bag}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="location">위치</Label>
                <Select
                  value={newLocation.location}
                  onValueChange={(value) => setNewLocation({ ...newLocation, location: value })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="위치 선택" />
                  </SelectTrigger>
                  <SelectContent>
                    {commonLocations.map((location) => (
                      <SelectItem key={location} value={location}>
                        {location}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>사진 (선택사항)</Label>
                <div className="space-y-2">
                  {capturedPhoto ? (
                    <div className="relative">
                      <img
                        src={capturedPhoto || "/placeholder.svg"}
                        alt="위치 사진"
                        className="w-full h-32 object-cover rounded-lg"
                      />
                      <Button
                        variant="outline"
                        size="icon"
                        className="absolute top-2 right-2 bg-transparent"
                        onClick={() => setCapturedPhoto(null)}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  ) : (
                    <Button variant="outline" onClick={() => fileInputRef.current?.click()} className="w-full">
                      <Camera className="mr-2 h-4 w-4" />
                      사진 추가
                    </Button>
                  )}
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="notes">메모 (선택사항)</Label>
                <Input
                  id="notes"
                  value={newLocation.notes}
                  onChange={(e) => setNewLocation({ ...newLocation, notes: e.target.value })}
                  placeholder="추가 정보나 메모"
                />
              </div>

              <div className="flex gap-2">
                <Button onClick={addNewLocation} className="flex-1">
                  기록하기
                </Button>
                <Button variant="outline" onClick={() => setIsAddingLocation(false)}>
                  취소
                </Button>
              </div>
            </div>
          </DialogContent>
        </Dialog>

        <input ref={fileInputRef} type="file" accept="image/*" onChange={handlePhotoUpload} className="hidden" />
      </Card>

      {/* 위치 목록 */}
      {filteredLocations.length === 0 ? (
        <Card className="p-8 text-center">
          <Package className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
          <h3 className="font-semibold mb-2">기록된 위치가 없습니다</h3>
          <p className="text-sm text-muted-foreground mb-4">첫 번째 물건의 위치를 기록해보세요</p>
          <Button onClick={() => setIsAddingLocation(true)}>
            <Plus className="h-4 w-4 mr-2" />
            위치 기록하기
          </Button>
        </Card>
      ) : (
        <Tabs defaultValue="list" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="list">목록 보기</TabsTrigger>
            <TabsTrigger value="bags">가방별 보기</TabsTrigger>
          </TabsList>

          <TabsContent value="list" className="space-y-3">
            {filteredLocations.map((location) => (
              <Card key={location.id} className="p-4">
                <div className="flex items-start gap-4">
                  {location.photo && (
                    <div className="w-20 h-20 flex-shrink-0">
                      <img
                        src={location.photo || "/placeholder.svg"}
                        alt={location.itemName}
                        className="w-full h-full object-cover rounded-lg"
                      />
                    </div>
                  )}
                  <div className="flex-1 space-y-2">
                    <div className="flex items-center justify-between">
                      <h3 className="font-semibold">{location.itemName}</h3>
                      <Button variant="ghost" size="icon" onClick={() => removeLocation(location.id)}>
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                    <div className="flex items-center gap-2 text-sm">
                      <Package className="h-4 w-4 text-muted-foreground" />
                      <span>{location.bagName}</span>
                      <Badge variant="secondary">{location.location}</Badge>
                    </div>
                    {location.notes && <p className="text-sm text-muted-foreground">{location.notes}</p>}
                    <div className="flex items-center gap-2 text-xs text-muted-foreground">
                      <MapPin className="h-3 w-3" />
                      <span>기록 시간: {location.timestamp}</span>
                    </div>
                  </div>
                </div>
              </Card>
            ))}
          </TabsContent>

          <TabsContent value="bags" className="space-y-4">
            {Object.entries(groupedLocations).map(([bagName, bagLocations]) => (
              <Card key={bagName} className="p-4">
                <div className="flex items-center gap-2 mb-3">
                  <Package className="h-5 w-5 text-primary" />
                  <h3 className="font-semibold">{bagName}</h3>
                  <Badge variant="outline">{bagLocations.length}개 아이템</Badge>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {bagLocations.map((location) => (
                    <div key={location.id} className="p-3 bg-muted/50 rounded-lg">
                      <div className="flex items-center justify-between mb-2">
                        <span className="font-medium">{location.itemName}</span>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-6 w-6"
                          onClick={() => removeLocation(location.id)}
                        >
                          <Trash2 className="h-3 w-3" />
                        </Button>
                      </div>
                      <div className="flex items-center gap-1 text-sm text-muted-foreground">
                        <MapPin className="h-3 w-3" />
                        <span>{location.location}</span>
                      </div>
                      {location.photo && (
                        <div className="mt-2">
                          <img
                            src={location.photo || "/placeholder.svg"}
                            alt={location.itemName}
                            className="w-full h-16 object-cover rounded"
                          />
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </Card>
            ))}
          </TabsContent>
        </Tabs>
      )}

      {/* 통계 */}
      <Card className="p-4">
        <h3 className="font-semibold mb-3">위치 추적 통계</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
          <div>
            <div className="text-2xl font-bold text-primary">{locations.length}</div>
            <div className="text-xs text-muted-foreground">총 기록</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-green-600">{Object.keys(groupedLocations).length}</div>
            <div className="text-xs text-muted-foreground">사용 가방</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-blue-600">{locations.filter((l) => l.photo).length}</div>
            <div className="text-xs text-muted-foreground">사진 기록</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-purple-600">{locations.filter((l) => l.notes).length}</div>
            <div className="text-xs text-muted-foreground">메모 포함</div>
          </div>
        </div>
      </Card>
    </div>
  )
}
