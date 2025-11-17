"use client"

import { Icons } from "./icons/custom-icons"

export function BottomNav({ activeTab, onTabChange }: any) {
  const tabs = [
    { id: "dashboard", label: "Dashboard", Icon: Icons.Dashboard },
    { id: "revenue", label: "Revenue", Icon: Icons.Sales },
    { id: "transactions", label: "Transactions", Icon: Icons.Expenses },
    { id: "settings", label: "Settings", Icon: Icons.Settings },
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
            <tab.Icon className="w-5 h-5 mb-1" />
            <span className="text-xs font-medium">{tab.label}</span>
          </button>
        ))}
      </div>
    </nav>
  )
}
