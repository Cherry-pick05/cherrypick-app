"use client"

import { useState } from "react"
import { ChevronDown, Plus, Trash2 } from "lucide-react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

interface Trip {
  id: string
  name: string
  destination: string
  startDate: string
  duration: string
}

export function HeaderWithTrip() {
  const [trips, setTrips] = useState<Trip[]>([
    {
      id: "1",
      name: "오사카 여행",
      destination: "일본 오사카",
      startDate: "2025-03-15",
      duration: "4박 5일",
    },
    {
      id: "2",
      name: "방콕 여행",
      destination: "태국 방콕",
      startDate: "2025-05-20",
      duration: "3박 4일",
    },
  ])
  const [currentTripId, setCurrentTripId] = useState("1")
  const [showTripModal, setShowTripModal] = useState(false)
  const [showAddModal, setShowAddModal] = useState(false)
  const [newTrip, setNewTrip] = useState({
    name: "",
    destination: "",
    startDate: "",
    duration: "",
  })

  const currentTrip = trips.find((t) => t.id === currentTripId)

  const handleAddTrip = () => {
    if (newTrip.name && newTrip.destination) {
      const trip: Trip = {
        id: Date.now().toString(),
        ...newTrip,
      }
      setTrips([...trips, trip])
      setCurrentTripId(trip.id)
      setNewTrip({ name: "", destination: "", startDate: "", duration: "" })
      setShowAddModal(false)
      setShowTripModal(false)
    }
  }

  const handleDeleteTrip = (id: string) => {
    if (trips.length > 1) {
      const newTrips = trips.filter((t) => t.id !== id)
      setTrips(newTrips)
      if (currentTripId === id) {
        setCurrentTripId(newTrips[0].id)
      }
    }
  }

  return (
    <>
      <header className="sticky top-0 z-50 w-full bg-background border-b border-border/40">
        <div className="container flex h-16 items-center justify-between px-4">
          <button
            onClick={() => setShowTripModal(true)}
            className="flex items-center gap-2 px-3 py-2 rounded-lg bg-muted/50 hover:bg-muted transition-colors"
          >
            <span className="text-base font-semibold text-foreground">{currentTrip?.name}</span>
            <ChevronDown className="h-4 w-4 text-muted-foreground" />
          </button>

          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground font-bold text-sm">
              🍒
            </div>
            <h1 className="text-xl font-bold text-foreground">cherry pick</h1>
          </div>
        </div>
      </header>

      <Dialog open={showTripModal} onOpenChange={setShowTripModal}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-center text-lg font-bold">여행 선택</DialogTitle>
          </DialogHeader>
          <div className="space-y-2 py-2">
            {trips.map((trip) => (
              <div
                key={trip.id}
                className={`flex items-center justify-between px-4 py-3 rounded-lg transition-all ${
                  currentTripId === trip.id
                    ? "bg-primary/10 border-2 border-primary/20"
                    : "bg-background hover:bg-muted border-2 border-transparent"
                }`}
              >
                <button
                  onClick={() => {
                    setCurrentTripId(trip.id)
                    setShowTripModal(false)
                  }}
                  className="flex-1 text-left"
                >
                  <div className="font-semibold text-foreground">{trip.name}</div>
                  <div className="text-sm text-muted-foreground">{trip.destination}</div>
                </button>
                {trips.length > 1 && (
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      handleDeleteTrip(trip.id)
                    }}
                    className="ml-2 p-2 rounded-md hover:bg-destructive/10 text-muted-foreground hover:text-destructive transition-colors"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                )}
              </div>
            ))}
            <button
              onClick={() => {
                setShowTripModal(false)
                setShowAddModal(true)
              }}
              className="w-full flex items-center justify-center gap-2 px-4 py-3 rounded-lg border-2 border-dashed border-muted-foreground/30 hover:border-primary/50 hover:bg-primary/5 text-muted-foreground hover:text-primary transition-all"
            >
              <Plus className="h-4 w-4" />
              <span className="font-medium">새 여행 추가</span>
            </button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Add Trip Modal */}
      <Dialog open={showAddModal} onOpenChange={setShowAddModal}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-center text-lg font-bold">새 여행 추가</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="trip-name">여행 이름</Label>
              <Input
                id="trip-name"
                placeholder="예: 오사카 여행"
                value={newTrip.name}
                onChange={(e) => setNewTrip({ ...newTrip, name: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="destination">목적지</Label>
              <Input
                id="destination"
                placeholder="예: 일본 오사카"
                value={newTrip.destination}
                onChange={(e) => setNewTrip({ ...newTrip, destination: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="start-date">출발 날짜</Label>
              <Input
                id="start-date"
                type="date"
                value={newTrip.startDate}
                onChange={(e) => setNewTrip({ ...newTrip, startDate: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="duration">여행 기간</Label>
              <Select value={newTrip.duration} onValueChange={(value) => setNewTrip({ ...newTrip, duration: value })}>
                <SelectTrigger id="duration">
                  <SelectValue placeholder="기간 선택" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="1박 2일">1박 2일</SelectItem>
                  <SelectItem value="2박 3일">2박 3일</SelectItem>
                  <SelectItem value="3박 4일">3박 4일</SelectItem>
                  <SelectItem value="4박 5일">4박 5일</SelectItem>
                  <SelectItem value="5박 6일">5박 6일</SelectItem>
                  <SelectItem value="6박 7일">6박 7일</SelectItem>
                  <SelectItem value="7박 이상">7박 이상</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <Button onClick={handleAddTrip} className="w-full bg-primary hover:bg-primary/90">
              추가
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}
