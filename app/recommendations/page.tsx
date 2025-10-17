import { TravelRecommendations } from "@/components/travel-recommendations"
import { Header } from "@/components/header"
import { Navigation } from "@/components/navigation"

export default function RecommendationsPage() {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="pb-20">
        <TravelRecommendations />
      </main>
      <Navigation />
    </div>
  )
}
