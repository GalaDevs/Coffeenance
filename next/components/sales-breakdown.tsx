"use client"

import { useState } from "react"

export function SalesBreakdown({ salesByMethod, totalSales }: any) {
  const [showDetails, setShowDetails] = useState(false)

  const methods = [
    { name: "Cash", key: "cash", icon: "💵", color: "bg-chart-1" },
    { name: "GCash", key: "gcash", icon: "📱", color: "bg-chart-2" },
    { name: "Grab", key: "grab", icon: "🚗", color: "bg-chart-3" },
    { name: "PayMaya", key: "paymaya", icon: "💳", color: "bg-chart-4" },
  ]

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">Sales by Method</h3>
        <button onClick={() => setShowDetails(!showDetails)} className="text-sm text-primary hover:underline">
          {showDetails ? "Hide" : "View"}
        </button>
      </div>

      {/* Quick Overview */}
      <div className="grid grid-cols-2 gap-3">
        {methods.map((method) => {
          const amount = salesByMethod[method.key] || 0
          const percentage = totalSales > 0 ? (amount / totalSales) * 100 : 0

          return (
            <div key={method.key} className="rounded-xl bg-card p-4 border border-border">
              <div className="flex items-center justify-between mb-3">
                <span className="text-2xl">{method.icon}</span>
                <span className="text-xs font-medium text-muted-foreground">{percentage.toFixed(0)}%</span>
              </div>
              <p className="text-xs text-muted-foreground mb-1">{method.name}</p>
              <p className="text-lg font-bold text-foreground">
                ₱{amount.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
              </p>

              {/* Progress bar */}
              <div className="mt-2 h-1.5 bg-secondary rounded-full overflow-hidden">
                <div className={`h-full ${method.color}`} style={{ width: `${percentage}%` }} />
              </div>
            </div>
          )
        })}
      </div>

      {/* Total */}
      <div className="rounded-xl bg-secondary p-4">
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium text-foreground">Total Sales</span>
          <span className="text-xl font-bold text-primary">
            ₱{totalSales.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
          </span>
        </div>
      </div>
    </div>
  )
}
