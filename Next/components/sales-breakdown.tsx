"use client"

import { useState } from "react"
import { Icons } from "@/components/icons/custom-icons"

export function SalesBreakdown({ salesByMethod, totalSales }: any) {
  const [showDetails, setShowDetails] = useState(false)

  const methods = [
    { name: "Cash", key: "cash", icon: Icons.Wallet, color: "bg-chart-1" },
    { name: "GCash", key: "gcash", icon: Icons.Mobile, color: "bg-chart-2" },
    { name: "Grab", key: "grab", icon: Icons.TrendUp, color: "bg-chart-3" },
    { name: "PayMaya", key: "paymaya", icon: Icons.CreditCard, color: "bg-chart-4" },
  ]

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold flex items-center gap-2">
          <Icons.BarChart className="w-5 h-5 text-primary" />
          Sales by Method
        </h3>
        <button
          onClick={() => setShowDetails(!showDetails)}
          className="text-sm text-primary hover:text-primary/80 font-medium transition-colors"
        >
          {showDetails ? "Hide" : "View"}
        </button>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {methods.map((method) => {
          const amount = salesByMethod[method.key] || 0
          const percentage = totalSales > 0 ? (amount / totalSales) * 100 : 0
          const IconComponent = method.icon

          return (
            <div
              key={method.key}
              className="group rounded-xl bg-gradient-to-br from-card to-card/50 hover:from-card hover:to-primary/5 p-4 border border-border hover:border-primary/50 transition-all hover:shadow-md active:scale-95"
            >
              <div className="flex items-center justify-between mb-3">
                <div className="p-2 rounded-lg bg-primary/10 group-hover:bg-primary/20 transition-colors">
                  <IconComponent className="w-5 h-5 text-primary" />
                </div>
                <span className="text-xs font-bold text-primary bg-primary/10 px-2 py-1 rounded-full">
                  {percentage.toFixed(0)}%
                </span>
              </div>
              <p className="text-xs text-muted-foreground mb-1 font-medium">{method.name}</p>
              <p className="text-lg font-bold text-foreground">
                ₱{amount.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
              </p>

              <div className="mt-3 h-2 bg-secondary rounded-full overflow-hidden">
                <div
                  className={`h-full ${method.color} rounded-full transition-all duration-500`}
                  style={{ width: `${percentage}%` }}
                />
              </div>
            </div>
          )
        })}
      </div>

      <div className="rounded-xl bg-gradient-to-r from-primary to-primary/80 p-4 text-primary-foreground shadow-lg">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Icons.TrendUp className="w-5 h-5" />
            <span className="text-sm font-medium opacity-90">Total Sales</span>
          </div>
          <span className="text-2xl font-bold">
            ₱{totalSales.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
          </span>
        </div>
      </div>
    </div>
  )
}
