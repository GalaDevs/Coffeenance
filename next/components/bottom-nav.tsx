"use client"

export function BottomNav({ activeTab, onTabChange }: any) {
  const tabs = [
    { id: "dashboard", label: "Dashboard", icon: "📊" },
    { id: "sales", label: "Sales", icon: "💰" },
    { id: "expenses", label: "Expenses", icon: "📉" },
    { id: "settings", label: "Settings", icon: "⚙️" },
  ]

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-card border-t border-border">
      <div className="flex justify-around items-center h-20 max-w-md mx-auto">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => onTabChange(tab.id)}
            className={`flex flex-col items-center justify-center w-14 h-14 rounded-lg transition-all ${
              activeTab === tab.id ? "bg-primary/10 text-primary" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <span className="text-xl mb-1">{tab.icon}</span>
            <span className="text-xs font-medium">{tab.label}</span>
          </button>
        ))}
      </div>
    </nav>
  )
}
