"use client"

import { useState } from "react"

export function SalesPage({ transactions }: { transactions: any[] }) {
  const [timeframe, setTimeframe] = useState("today")
  const incomeTransactions = transactions.filter((t) => t.type === "income")

  const totalSales = incomeTransactions.reduce((sum, t) => sum + t.amount, 0)

  const salesByMethod = {
    Cash: incomeTransactions.filter((t) => t.category === "Cash").reduce((sum, t) => sum + t.amount, 0),
    GCash: incomeTransactions.filter((t) => t.category === "GCash").reduce((sum, t) => sum + t.amount, 0),
    Grab: incomeTransactions.filter((t) => t.category === "Grab").reduce((sum, t) => sum + t.amount, 0),
    PayMaya: incomeTransactions.filter((t) => t.category === "PayMaya").reduce((sum, t) => sum + t.amount, 0),
  }

  const salesData = Object.entries(salesByMethod)
    .filter(([_, amount]) => amount > 0)
    .map(([method, amount]) => ({
      method,
      amount,
      percentage: Math.round((amount / totalSales) * 100) || 0,
    }))

  return (
    <div className="px-4 pt-6 pb-4 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Sales Report</h1>
          <p className="text-sm text-muted-foreground">Payment method breakdown</p>
        </div>
      </div>

      {/* Total Sales Card */}
      <div className="bg-gradient-to-br from-amber-600 to-amber-700 rounded-2xl p-6 text-white shadow-lg">
        <p className="text-sm font-medium opacity-90">Total Sales</p>
        <p className="text-4xl font-bold mt-2">₱{totalSales.toLocaleString()}</p>
        <p className="text-xs mt-3 opacity-75">{incomeTransactions.length} transactions</p>
      </div>

      {/* Sales by Method */}
      <div className="space-y-3">
        <h2 className="text-lg font-bold text-foreground">Sales by Method</h2>
        {salesData.length > 0 ? (
          salesData.map((item) => (
            <div key={item.method} className="bg-card rounded-lg p-4 border border-border">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium text-foreground">{item.method}</span>
                <span className="text-sm font-bold text-primary">₱{item.amount.toLocaleString()}</span>
              </div>
              <div className="w-full bg-secondary rounded-full h-2 overflow-hidden">
                <div
                  className="bg-gradient-to-r from-amber-500 to-amber-600 h-full transition-all"
                  style={{ width: `${item.percentage}%` }}
                />
              </div>
              <div className="text-xs text-muted-foreground mt-1">{item.percentage}% of sales</div>
            </div>
          ))
        ) : (
          <div className="text-center py-8 text-muted-foreground">No sales recorded yet</div>
        )}
      </div>

      {/* Recent Sales Transactions */}
      <div className="space-y-3">
        <h2 className="text-lg font-bold text-foreground">Recent Sales</h2>
        {incomeTransactions.length > 0 ? (
          <div className="space-y-2">
            {incomeTransactions.slice(0, 10).map((transaction) => (
              <div
                key={transaction.id}
                className="flex items-center justify-between bg-card rounded-lg p-4 border border-border"
              >
                <div>
                  <p className="font-medium text-foreground">{transaction.description}</p>
                  <p className="text-xs text-muted-foreground">{transaction.category}</p>
                </div>
                <p className="font-bold text-green-600">+₱{transaction.amount.toLocaleString()}</p>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-muted-foreground">No sales yet</div>
        )}
      </div>
    </div>
  )
}
