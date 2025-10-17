import { PackingManager } from "@/components/packing-manager"
import { HeaderWithTrip } from "@/components/header-with-trip"
import { Navigation } from "@/components/navigation"

export default function LuggagePage() {
  return (
    <div className="min-h-screen bg-background">
      <HeaderWithTrip />
      <main className="pb-20">
        <PackingManager />
      </main>
      <Navigation />
    </div>
  )
}
