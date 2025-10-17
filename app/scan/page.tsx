import { ItemScanner } from "@/components/item-scanner"
import { HeaderWithTrip } from "@/components/header-with-trip"
import { Navigation } from "@/components/navigation"

export default function ScanPage() {
  return (
    <div className="min-h-screen bg-background">
      <HeaderWithTrip />
      <main className="pb-20">
        <ItemScanner />
      </main>
      <Navigation />
    </div>
  )
}
