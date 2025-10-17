"use client"

import type React from "react"

import { useState, useRef, useCallback } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { Camera, Upload, X, CheckCircle, AlertTriangle, Info } from "lucide-react"
import { cn } from "@/lib/utils"

interface ScanResult {
  item: string
  category: string
  volume?: string
  weight?: string
  carryOnAllowed: boolean
  checkedAllowed: boolean
  restrictions: string[]
  confidence: number
}

export function ItemScanner() {
  const [isScanning, setIsScanning] = useState(false)
  const [scanResult, setScanResult] = useState<ScanResult | null>(null)
  const [selectedImage, setSelectedImage] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [isCameraActive, setIsCameraActive] = useState(false)

  const startCamera = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment" },
      })
      if (videoRef.current) {
        videoRef.current.srcObject = stream
        setIsCameraActive(true)
      }
    } catch (error) {
      console.error("카메라 접근 실패:", error)
    }
  }, [])

  const stopCamera = useCallback(() => {
    if (videoRef.current?.srcObject) {
      const stream = videoRef.current.srcObject as MediaStream
      stream.getTracks().forEach((track) => track.stop())
      videoRef.current.srcObject = null
      setIsCameraActive(false)
    }
  }, [])

  const capturePhoto = useCallback(() => {
    if (videoRef.current && canvasRef.current) {
      const canvas = canvasRef.current
      const video = videoRef.current
      canvas.width = video.videoWidth
      canvas.height = video.videoHeight

      const ctx = canvas.getContext("2d")
      if (ctx) {
        ctx.drawImage(video, 0, 0)
        const imageData = canvas.toDataURL("image/jpeg")
        setSelectedImage(imageData)
        stopCamera()
        simulateScan(imageData)
      }
    }
  }, [stopCamera])

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        const imageData = e.target?.result as string
        setSelectedImage(imageData)
        simulateScan(imageData)
      }
      reader.readAsDataURL(file)
    }
  }

  const simulateScan = async (imageData: string) => {
    setIsScanning(true)
    setScanResult(null)

    // 실제 구현에서는 AI API 호출
    await new Promise((resolve) => setTimeout(resolve, 2000))

    // 모의 결과 데이터
    const mockResults: ScanResult[] = [
      {
        item: "화장품 (토너)",
        category: "액체류",
        volume: "150ml",
        carryOnAllowed: true,
        checkedAllowed: true,
        restrictions: ["100ml 이하 용기에 담아야 함", "투명 지퍼백에 보관"],
        confidence: 92,
      },
      {
        item: "보조배터리",
        category: "전자기기",
        weight: "20,000mAh",
        carryOnAllowed: true,
        checkedAllowed: false,
        restrictions: ["기내 수하물만 가능", "100Wh 이하만 허용"],
        confidence: 88,
      },
      {
        item: "헤어드라이어",
        category: "전자기기",
        carryOnAllowed: true,
        checkedAllowed: true,
        restrictions: ["전압 확인 필요", "플러그 어댑터 준비"],
        confidence: 95,
      },
    ]

    const randomResult = mockResults[Math.floor(Math.random() * mockResults.length)]
    setScanResult(randomResult)
    setIsScanning(false)
  }

  const resetScan = () => {
    setScanResult(null)
    setSelectedImage(null)
    stopCamera()
  }

  return (
    <div className="container px-4 py-6 space-y-6">
      <div className="text-center">
        <h1 className="text-2xl font-bold">물품 스캔</h1>
      </div>

      {!selectedImage && !isCameraActive && (
        <div className="space-y-4">
          <Card className="p-8 text-center space-y-4">
            <div className="mx-auto w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center">
              <Camera className="h-8 w-8 text-primary" />
            </div>
            <div className="flex flex-col sm:flex-row gap-3 justify-center">
              <Button onClick={startCamera} className="flex items-center gap-2">
                <Camera className="h-4 w-4" />
                카메라 촬영
              </Button>
              <Button
                variant="outline"
                onClick={() => fileInputRef.current?.click()}
                className="flex items-center gap-2"
              >
                <Upload className="h-4 w-4" />
                사진 업로드
              </Button>
            </div>
          </Card>
        </div>
      )}

      {isCameraActive && (
        <Card className="p-4 space-y-4">
          <div className="relative">
            <video ref={videoRef} autoPlay playsInline className="w-full rounded-lg" />
            <div className="absolute inset-0 border-2 border-primary/50 rounded-lg pointer-events-none">
              <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-48 h-48 border-2 border-primary rounded-lg"></div>
            </div>
          </div>
          <div className="flex gap-2 justify-center">
            <Button onClick={capturePhoto} size="lg">
              <Camera className="mr-2 h-5 w-5" />
              촬영하기
            </Button>
            <Button variant="outline" onClick={stopCamera}>
              <X className="mr-2 h-4 w-4" />
              취소
            </Button>
          </div>
        </Card>
      )}

      {selectedImage && (
        <Card className="p-4 space-y-4">
          <div className="relative">
            <img
              src={selectedImage || "/placeholder.svg"}
              alt="스캔할 물품"
              className="w-full rounded-lg max-h-64 object-cover"
            />
            <Button variant="outline" size="icon" className="absolute top-2 right-2 bg-transparent" onClick={resetScan}>
              <X className="h-4 w-4" />
            </Button>
          </div>

          {isScanning && (
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-primary border-t-transparent"></div>
                <span className="text-sm">AI가 물품을 분석하고 있어요...</span>
              </div>
              <Progress value={75} className="w-full" />
            </div>
          )}

          {scanResult && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold">스캔 결과</h3>
                <Badge variant="secondary">정확도 {scanResult.confidence}%</Badge>
              </div>

              <Card className="p-4 space-y-3">
                <div className="flex items-center gap-2">
                  <h4 className="font-semibold text-lg">{scanResult.item}</h4>
                  <Badge variant="outline">{scanResult.category}</Badge>
                </div>

                {scanResult.volume && (
                  <div className="flex items-center gap-2 text-sm">
                    <Info className="h-4 w-4 text-muted-foreground" />
                    <span>용량: {scanResult.volume}</span>
                  </div>
                )}

                {scanResult.weight && (
                  <div className="flex items-center gap-2 text-sm">
                    <Info className="h-4 w-4 text-muted-foreground" />
                    <span>용량: {scanResult.weight}</span>
                  </div>
                )}

                <div className="grid grid-cols-2 gap-4">
                  <div
                    className={cn(
                      "p-3 rounded-lg border text-center space-y-1",
                      scanResult.carryOnAllowed
                        ? "bg-green-50 border-green-200 text-green-800"
                        : "bg-red-50 border-red-200 text-red-800",
                    )}
                  >
                    {scanResult.carryOnAllowed ? (
                      <CheckCircle className="h-5 w-5 mx-auto" />
                    ) : (
                      <X className="h-5 w-5 mx-auto" />
                    )}
                    <div className="text-sm font-medium">기내 수하물</div>
                    <div className="text-xs">{scanResult.carryOnAllowed ? "허용" : "불가"}</div>
                  </div>

                  <div
                    className={cn(
                      "p-3 rounded-lg border text-center space-y-1",
                      scanResult.checkedAllowed
                        ? "bg-green-50 border-green-200 text-green-800"
                        : "bg-red-50 border-red-200 text-red-800",
                    )}
                  >
                    {scanResult.checkedAllowed ? (
                      <CheckCircle className="h-5 w-5 mx-auto" />
                    ) : (
                      <X className="h-5 w-5 mx-auto" />
                    )}
                    <div className="text-sm font-medium">위탁 수하물</div>
                    <div className="text-xs">{scanResult.checkedAllowed ? "허용" : "불가"}</div>
                  </div>
                </div>

                {scanResult.restrictions.length > 0 && (
                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <AlertTriangle className="h-4 w-4 text-amber-500" />
                      <span className="font-medium text-sm">주의사항</span>
                    </div>
                    <ul className="space-y-1">
                      {scanResult.restrictions.map((restriction, index) => (
                        <li key={index} className="text-sm text-muted-foreground flex items-start gap-2">
                          <span className="w-1 h-1 bg-muted-foreground rounded-full mt-2 flex-shrink-0"></span>
                          {restriction}
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                <div className="flex gap-2">
                  <Button className="flex-1">짐 리스트에 추가</Button>
                  <Button variant="outline" onClick={resetScan}>
                    다시 스캔
                  </Button>
                </div>
              </Card>
            </div>
          )}
        </Card>
      )}

      <input ref={fileInputRef} type="file" accept="image/*" onChange={handleFileUpload} className="hidden" />

      <canvas ref={canvasRef} className="hidden" />
    </div>
  )
}
