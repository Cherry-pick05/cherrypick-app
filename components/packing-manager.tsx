"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Checkbox } from "@/components/ui/checkbox"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Package, Plus, Trash2, MapPin, CheckCircle, Circle, Briefcase, ShoppingBag, Search } from "lucide-react"

interface PackingItem {
  id: string
  name: string
  category: string
  packed: boolean
  bagId: string
  location?: string
  weight?: string
  notes?: string
}

interface Bag {
  id: string
  name: string
  type: string
  color: string
  items: PackingItem[]
}

export function PackingManager() {
  const [bags, setBags] = useState<Bag[]>([
    {
      id: "carry-on",
      name: "기내용 캐리어",
      type: "carry-on",
      color: "bg-blue-500",
      items: [
        { id: "1", name: "여권", category: "서류", packed: true, bagId: "carry-on", location: "앞주머니" },
        { id: "2", name: "충전기", category: "전자기기", packed: true, bagId: "carry-on", location: "메인칸" },
        { id: "3", name: "화장품", category: "세면용품", packed: false, bagId: "carry-on", location: "지퍼백" },
        { id: "4", name: "약품", category: "의료용품", packed: true, bagId: "carry-on", location: "앞주머니" },
      ],
    },
    {
      id: "checked",
      name: "위탁용 캐리어",
      type: "checked",
      color: "bg-green-500",
      items: [
        { id: "5", name: "옷가지", category: "의류", packed: true, bagId: "checked", location: "메인칸" },
        { id: "6", name: "신발", category: "신발", packed: true, bagId: "checked", location: "신발칸" },
        { id: "7", name: "헤어드라이어", category: "전자기기", packed: false, bagId: "checked", location: "메인칸" },
        { id: "8", name: "선물", category: "기타", packed: false, bagId: "checked", location: "메인칸" },
      ],
    },
    {
      id: "backpack",
      name: "백팩",
      type: "personal",
      color: "bg-purple-500",
      items: [
        { id: "9", name: "노트북", category: "전자기기", packed: true, bagId: "backpack", location: "노트북칸" },
        { id: "10", name: "책", category: "도서", packed: false, bagId: "backpack", location: "메인칸" },
        { id: "11", name: "간식", category: "음식", packed: true, bagId: "backpack", location: "앞주머니" },
      ],
    },
  ])

  const [selectedBag, setSelectedBag] = useState<string>("carry-on")
  const [newItemName, setNewItemName] = useState("")
  const [newItemCategory, setNewItemCategory] = useState("")
  const [isAddingItem, setIsAddingItem] = useState(false)
  const [isAddingBag, setIsAddingBag] = useState(false)
  const [newBagName, setNewBagName] = useState("")
  const [newBagType, setNewBagType] = useState("")
  const [searchQuery, setSearchQuery] = useState("")

  const categories = [
    "의류",
    "신발",
    "세면용품",
    "화장품",
    "전자기기",
    "서류",
    "의료용품",
    "액세서리",
    "음식",
    "기타",
    "도서",
    "운동용품",
    "선물",
  ]

  const addNewBag = () => {
    if (!newBagName.trim() || !newBagType) return

    const colors = ["bg-blue-500", "bg-green-500", "bg-purple-500", "bg-orange-500", "bg-pink-500", "bg-teal-500"]
    const randomColor = colors[Math.floor(Math.random() * colors.length)]

    const newBag: Bag = {
      id: Date.now().toString(),
      name: newBagName,
      type: newBagType,
      color: randomColor,
      items: [],
    }

    setBags([...bags, newBag])
    setNewBagName("")
    setNewBagType("")
    setIsAddingBag(false)
  }

  const toggleItemPacked = (bagId: string, itemId: string) => {
    setBags(
      bags.map((bag) =>
        bag.id === bagId
          ? {
              ...bag,
              items: bag.items.map((item) => (item.id === itemId ? { ...item, packed: !item.packed } : item)),
            }
          : bag,
      ),
    )
  }

  const addNewItem = () => {
    if (!newItemName.trim() || !newItemCategory) return

    const newItem: PackingItem = {
      id: Date.now().toString(),
      name: newItemName,
      category: newItemCategory,
      packed: false,
      bagId: selectedBag,
      location: "메인칸",
    }

    setBags(bags.map((bag) => (bag.id === selectedBag ? { ...bag, items: [...bag.items, newItem] } : bag)))

    setNewItemName("")
    setNewItemCategory("")
    setIsAddingItem(false)
  }

  const removeItem = (bagId: string, itemId: string) => {
    setBags(
      bags.map((bag) => (bag.id === bagId ? { ...bag, items: bag.items.filter((item) => item.id !== itemId) } : bag)),
    )
  }

  const getBagIcon = (type: string) => {
    switch (type) {
      case "carry-on":
        return Briefcase
      case "checked":
        return Package
      case "personal":
        return ShoppingBag
      default:
        return Package
    }
  }

  const getPackingProgress = (bag: Bag) => {
    const packedItems = bag.items.filter((item) => item.packed).length
    const totalItems = bag.items.length
    return totalItems > 0 ? Math.round((packedItems / totalItems) * 100) : 0
  }

  const filterItemsBySearch = (items: PackingItem[]) => {
    if (!searchQuery.trim()) return items
    return items.filter(
      (item) =>
        item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.location?.toLowerCase().includes(searchQuery.toLowerCase()),
    )
  }

  return (
    <div className="container px-4 py-6 space-y-6">
      <div className="text-center">
        <h1 className="text-2xl font-bold">cherry pick</h1>
      </div>

      <div className="relative max-w-md mx-auto">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          type="text"
          placeholder="물건 검색..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="pl-10"
        />
      </div>

      {/* 가방 개요 카드들 */}
      <div className="relative">
        <div className="flex gap-4 overflow-x-auto pb-4 snap-x snap-mandatory scrollbar-hide">
          {bags.map((bag) => {
            const BagIcon = getBagIcon(bag.type)
            const packedCount = bag.items.filter((item) => item.packed).length

            return (
              <Card
                key={bag.id}
                className={`flex-shrink-0 w-[240px] p-4 cursor-pointer transition-all hover:shadow-md snap-start ${
                  selectedBag === bag.id ? "ring-2 ring-primary" : ""
                }`}
                onClick={() => setSelectedBag(bag.id)}
              >
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div className={`w-10 h-10 rounded-lg ${bag.color} flex items-center justify-center`}>
                        <BagIcon className="h-5 w-5 text-white" />
                      </div>
                      <div>
                        <h3 className="font-semibold">{bag.name}</h3>
                      </div>
                    </div>
                  </div>

                  <Badge
                    variant={packedCount === bag.items.length && bag.items.length > 0 ? "default" : "secondary"}
                    className="w-full justify-center"
                  >
                    {packedCount}/{bag.items.length} 완료
                  </Badge>
                </div>
              </Card>
            )
          })}

          <Dialog open={isAddingBag} onOpenChange={setIsAddingBag}>
            <DialogTrigger asChild>
              <button className="flex-shrink-0 w-[240px] h-[120px] rounded-lg border-2 border-dashed border-muted-foreground/30 hover:border-primary/50 transition-colors flex items-center justify-center group snap-start">
                <div className="text-center">
                  <div className="w-16 h-16 rounded-full bg-primary/10 group-hover:bg-primary/20 flex items-center justify-center mx-auto mb-2 transition-colors">
                    <Plus className="h-8 w-8 text-primary" />
                  </div>
                  <p className="text-sm font-medium text-muted-foreground group-hover:text-primary transition-colors">
                    가방 추가
                  </p>
                </div>
              </button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>새 가방 추가</DialogTitle>
              </DialogHeader>
              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="bag-name">가방 이름</Label>
                  <Input
                    id="bag-name"
                    value={newBagName}
                    onChange={(e) => setNewBagName(e.target.value)}
                    placeholder="예: 보조 가방, 크로스백"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="bag-type">가방 종류</Label>
                  <Select value={newBagType} onValueChange={setNewBagType}>
                    <SelectTrigger>
                      <SelectValue placeholder="종류 선택" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="carry-on">기내용</SelectItem>
                      <SelectItem value="checked">위탁용</SelectItem>
                      <SelectItem value="personal">개인 소지품</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="flex gap-2">
                  <Button onClick={addNewBag} className="flex-1">
                    추가하기
                  </Button>
                  <Button variant="outline" onClick={() => setIsAddingBag(false)}>
                    취소
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* 선택된 가방의 상세 내용 */}
      <Tabs value={selectedBag} onValueChange={setSelectedBag} className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          {bags.map((bag) => (
            <TabsTrigger key={bag.id} value={bag.id} className="text-xs">
              {bag.name}
            </TabsTrigger>
          ))}
        </TabsList>

        {bags.map((bag) => {
          const filteredItems = filterItemsBySearch(bag.items)

          return (
            <TabsContent key={bag.id} value={bag.id} className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <h2 className="text-xl font-semibold">{bag.name}</h2>
                  <Badge variant="outline">{bag.items.length}개 아이템</Badge>
                </div>

                <Dialog open={isAddingItem} onOpenChange={setIsAddingItem}>
                  <DialogTrigger asChild>
                    <Button size="sm">
                      <Plus className="h-4 w-4 mr-1" />
                      아이템 추가
                    </Button>
                  </DialogTrigger>
                  <DialogContent>
                    <DialogHeader>
                      <DialogTitle>새 아이템 추가</DialogTitle>
                    </DialogHeader>
                    <div className="space-y-4">
                      <div className="space-y-2">
                        <Label htmlFor="item-name">아이템 이름</Label>
                        <Input
                          id="item-name"
                          value={newItemName}
                          onChange={(e) => setNewItemName(e.target.value)}
                          placeholder="예: 여권, 충전기, 옷가지"
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="item-category">카테고리</Label>
                        <Select value={newItemCategory} onValueChange={setNewItemCategory}>
                          <SelectTrigger>
                            <SelectValue placeholder="카테고리 선택" />
                          </SelectTrigger>
                          <SelectContent>
                            {categories.map((category) => (
                              <SelectItem key={category} value={category}>
                                {category}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                      <div className="flex gap-2">
                        <Button onClick={addNewItem} className="flex-1">
                          추가하기
                        </Button>
                        <Button variant="outline" onClick={() => setIsAddingItem(false)}>
                          취소
                        </Button>
                      </div>
                    </div>
                  </DialogContent>
                </Dialog>
              </div>

              <div className="space-y-3">
                {filteredItems.length === 0 ? (
                  <Card className="p-8 text-center">
                    <Package className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                    <h3 className="font-semibold mb-2">{searchQuery ? "검색 결과가 없습니다" : "아이템이 없습니다"}</h3>
                    <p className="text-sm text-muted-foreground mb-4">
                      {searchQuery ? "다른 검색어를 시도해보세요" : "첫 번째 아이템을 추가해보세요"}
                    </p>
                    {!searchQuery && (
                      <Button onClick={() => setIsAddingItem(true)}>
                        <Plus className="h-4 w-4 mr-2" />
                        아이템 추가
                      </Button>
                    )}
                  </Card>
                ) : (
                  filteredItems.map((item) => (
                    <Card key={item.id} className="p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3 flex-1">
                          <Checkbox checked={item.packed} onCheckedChange={() => toggleItemPacked(bag.id, item.id)} />
                          <div className="flex-1">
                            <div className="flex items-center gap-2">
                              <span
                                className={`font-medium ${item.packed ? "line-through text-muted-foreground" : ""}`}
                              >
                                {item.name}
                              </span>
                              <Badge variant="secondary" className="text-xs">
                                {item.category}
                              </Badge>
                            </div>
                            {item.location && (
                              <div className="flex items-center gap-1 mt-1">
                                <MapPin className="h-3 w-3 text-muted-foreground" />
                                <span className="text-xs text-muted-foreground">{item.location}</span>
                              </div>
                            )}
                          </div>
                        </div>

                        <div className="flex items-center gap-2">
                          {item.packed ? (
                            <CheckCircle className="h-4 w-4 text-green-600" />
                          ) : (
                            <Circle className="h-4 w-4 text-muted-foreground" />
                          )}
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => removeItem(bag.id, item.id)}
                            className="h-8 w-8"
                          >
                            <Trash2 className="h-3 w-3" />
                          </Button>
                        </div>
                      </div>
                    </Card>
                  ))
                )}
              </div>
            </TabsContent>
          )
        })}
      </Tabs>
    </div>
  )
}
