"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Plus, MapPin, Calendar, Trash2 } from "lucide-react"

interface Trip {
  id: string
  name: string
  destination: string
  startDate: string
  endDate: string
  duration: string
}

interface TripSelectorProps {
  onTripChange?: (tripId: string) => void
}

export function TripSelector({ onTripChange }: TripSelectorProps) {
  const [trips, setTrips] = useState<Trip[]>([
    {
      id: "trip-1",
      name: "오사카 여행",
      destination: "일본 오사카",
      startDate: "2025-03-15",
      endDate: "2025-03-20",
      duration: "4박 5일",
    },
  ])

  const [selectedTripId, setSelectedTripId] = useState<string>("trip-1")
  const [isAddingTrip, setIsAddingTrip] = useState(false)
  const [newTripName, setNewTripName] = useState("")
  const [newTripDestination, setNewTripDestination] = useState("")
  const [newTripStartDate, setNewTripStartDate] = useState("")
  const [newTripEndDate, setNewTripEndDate] = useState("")
  const [newTripDuration, setNewTripDuration] = useState("")

  const selectedTrip = trips.find((trip) => trip.id === selectedTripId)

  const addNewTrip = () => {
    if (!newTripName.trim() || !newTripDestination.trim()) return

    const newTrip: Trip = {
      id: `trip-${Date.now()}`,
      name: newTripName,
      destination: newTripDestination,
      startDate: newTripStartDate,
      endDate: newTripEndDate,
      duration: newTripDuration,
    }

    setTrips([...trips, newTrip])
    setSelectedTripId(newTrip.id)
    onTripChange?.(newTrip.id)

    // Reset form
    setNewTripName("")
    setNewTripDestination("")
    setNewTripStartDate("")
    setNewTripEndDate("")
    setNewTripDuration("")
    setIsAddingTrip(false)
  }

  const deleteTrip = (tripId: string) => {
    if (trips.length === 1) {
      alert("최소 하나의 여행은 있어야 합니다")
      return
    }

    const updatedTrips = trips.filter((trip) => trip.id !== tripId)
    setTrips(updatedTrips)

    if (selectedTripId === tripId) {
      setSelectedTripId(updatedTrips[0].id)
      onTripChange?.(updatedTrips[0].id)
    }
  }

  const handleTripChange = (tripId: string) => {
    setSelectedTripId(tripId)
    onTripChange?.(tripId)
  }

  return (
    <div className="space-y-4">
      <Card className="p-4 bg-white border shadow-sm">
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <Label className="text-sm font-medium text-muted-foreground">현재 여행</Label>
            <Dialog open={isAddingTrip} onOpenChange={setIsAddingTrip}>
              <DialogTrigger asChild>
                <Button variant="ghost" size="sm" className="h-8 text-primary">
                  <Plus className="h-4 w-4 mr-1" />새 여행
                </Button>
              </DialogTrigger>
              <DialogContent className="bg-white">
                <DialogHeader>
                  <DialogTitle className="text-center">새 여행 추가</DialogTitle>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="trip-name">여행 이름</Label>
                    <Input
                      id="trip-name"
                      value={newTripName}
                      onChange={(e) => setNewTripName(e.target.value)}
                      placeholder="예: 오사카 여행"
                      className="bg-white"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="trip-destination">목적지</Label>
                    <Input
                      id="trip-destination"
                      value={newTripDestination}
                      onChange={(e) => setNewTripDestination(e.target.value)}
                      placeholder="예: 일본 오사카"
                      className="bg-white"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="trip-duration">여행 기간</Label>
                    <Input
                      id="trip-duration"
                      value={newTripDuration}
                      onChange={(e) => setNewTripDuration(e.target.value)}
                      placeholder="예: 4박 5일"
                      className="bg-white"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-2">
                      <Label htmlFor="trip-start">출발 날짜</Label>
                      <Input
                        id="trip-start"
                        type="date"
                        value={newTripStartDate}
                        onChange={(e) => setNewTripStartDate(e.target.value)}
                        className="bg-white"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="trip-end">도착 날짜</Label>
                      <Input
                        id="trip-end"
                        type="date"
                        value={newTripEndDate}
                        onChange={(e) => setNewTripEndDate(e.target.value)}
                        className="bg-white"
                      />
                    </div>
                  </div>
                  <Button onClick={addNewTrip} className="w-full bg-primary hover:bg-primary/90">
                    추가하기
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          </div>

          <Select value={selectedTripId} onValueChange={handleTripChange}>
            <SelectTrigger className="w-full bg-white border-muted">
              <SelectValue />
            </SelectTrigger>
            <SelectContent className="bg-white">
              {trips.map((trip) => (
                <SelectItem key={trip.id} value={trip.id}>
                  <div className="flex items-center gap-2">
                    <span className="font-medium">{trip.name}</span>
                    <span className="text-xs text-muted-foreground">· {trip.destination}</span>
                  </div>
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          {selectedTrip && (
            <div className="pt-2 space-y-2 border-t">
              <div className="flex items-center gap-2 text-sm">
                <MapPin className="h-4 w-4 text-muted-foreground" />
                <span className="text-muted-foreground">{selectedTrip.destination}</span>
              </div>
              {selectedTrip.duration && (
                <div className="flex items-center gap-2 text-sm">
                  <Calendar className="h-4 w-4 text-muted-foreground" />
                  <span className="text-muted-foreground">{selectedTrip.duration}</span>
                </div>
              )}
              {trips.length > 1 && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => deleteTrip(selectedTripId)}
                  className="w-full text-destructive hover:text-destructive hover:bg-destructive/10"
                >
                  <Trash2 className="h-4 w-4 mr-2" />이 여행 삭제
                </Button>
              )}
            </div>
          )}
        </div>
      </Card>
    </div>
  )
}
