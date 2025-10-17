import { ItemLocationTracker } from "@/components/item-location-tracker"
import { Header } from "@/components/header"
import { Navigation } from "@/components/navigation"

export default function TrackerPage() {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="pb-20">
        <ItemLocationTracker />
      </main>
      <Navigation />
    </div>
  )
}
