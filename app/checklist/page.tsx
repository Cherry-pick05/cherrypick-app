import { RegulationChecker } from "@/components/regulation-checker"
import { Header } from "@/components/header"
import { Navigation } from "@/components/navigation"

export default function ChecklistPage() {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="pb-20">
        <RegulationChecker />
      </main>
      <Navigation />
    </div>
  )
}
