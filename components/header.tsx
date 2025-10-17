export function Header() {
  return (
    <header className="sticky top-0 z-50 w-full bg-background">
      <div className="container flex h-16 items-center justify-end px-4">
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground font-bold text-sm">
            🍒
          </div>
          <h1 className="text-xl font-bold text-foreground">cherry pick</h1>
        </div>
      </div>
    </header>
  )
}
