"use client"

import { Button } from "@/components/ui/button"
import { Camera, Plane, Cherry, MapPin } from "lucide-react"
import { usePathname } from "next/navigation"
import Link from "next/link"

export function Navigation() {
  const pathname = usePathname()

  const navItems = [
    { icon: Cherry, label: "체리픽", href: "/luggage" },
    { icon: Camera, label: "스캔", href: "/scan" },
    { icon: Plane, label: "항공 규정", href: "/checklist" },
    { icon: MapPin, label: "추천", href: "/recommendations" },
  ]

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-background border-t border-border">
      <div className="container px-4">
        <div className="flex items-center justify-around py-3">
          {navItems.map((item, index) => {
            const isActive = pathname === item.href
            return (
              <Link key={index} href={item.href}>
                <Button
                  variant="ghost"
                  size="sm"
                  className={`flex flex-col gap-1 h-auto py-2 px-4 ${
                    isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
                  }`}
                >
                  <item.icon className="h-6 w-6" />
                  <span className="text-xs font-medium">{item.label}</span>
                </Button>
              </Link>
            )
          })}
        </div>
      </div>
    </nav>
  )
}
