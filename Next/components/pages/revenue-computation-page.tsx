"use client"

import { useState } from "react"

export function RevenueComputationPage({ transactions }: { transactions: any[] }) {
  const [timeframe, setTimeframe] = useState("today")
  const revenueTransactions = transactions.filter((t) => t.type === "revenue")

  const totalRevenue = revenueTransactions.reduce((sum, t) => sum + t.amount, 0)

  const revenueByMethod = {
    Cash: revenueTransactions.filter((t) => t.paymentMethod === "Cash").reduce((sum, t) => sum + t.amount, 0),
    GCash: revenueTransactions.filter((t) => t.paymentMethod === "GCash").reduce((sum, t) => sum + t.amount, 0),
    Grab: revenueTransactions.filter((t) => t.paymentMethod === "Grab").reduce((sum, t) => sum + t.amount, 0),
    PayMaya: revenueTransactions.filter((t) => t.paymentMethod === "PayMaya").reduce((sum, t) => sum + t.amount, 0),
    Others: revenueTransactions.filter((t) => t.paymentMethod === "Others").reduce((sum, t) => sum + t.amount, 0),
  }

  const revenueData = Object.entries(revenueByMethod)
    .filter(([_, amount]) => amount > 0)
    .map(([method, amount]) => ({
      method,
      amount,
      percentage: Math.round((amount / totalRevenue) * 100) || 0,
    }))

  return (
    <div className="px-4 pt-6 pb-4 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Revenue Computation</h1>
          <p className="text-sm text-muted-foreground">Payment method breakdown</p>
        </div>
      </div>

      {/* Total Revenue Card */}
      <div className="bg-gradient-to-br from-green-600 to-green-700 rounded-2xl p-6 text-white shadow-lg">
        <p className="text-sm font-medium opacity-90">Total Revenue</p>
        <p className="text-4xl font-bold mt-2">₱{totalRevenue.toLocaleString()}</p>
        <p className="text-xs mt-3 opacity-75">{revenueTransactions.length} transactions</p>
      </div>

      {/* Revenue by Method */}
      <div className="space-y-3">
        <h2 className="text-lg font-bold text-foreground">Revenue by Payment Method</h2>
        {revenueData.length > 0 ? (
          revenueData.map((item) => (
            <div key={item.method} className="bg-card rounded-lg p-4 border border-border">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium text-foreground">{item.method}</span>
                <span className="text-sm font-bold text-green-600">₱{item.amount.toLocaleString()}</span>
              </div>
              <div className="w-full bg-secondary rounded-full h-2 overflow-hidden">
                <div
                  className="bg-gradient-to-r from-green-500 to-green-600 h-full transition-all"
                  style={{ width: `${item.percentage}%` }}
                />
              </div>
              <div className="text-xs text-muted-foreground mt-1">{item.percentage}% of revenue</div>
            </div>
          ))
        ) : (
          <div className="text-center py-8 text-muted-foreground">No revenue recorded yet</div>
        )}
      </div>

      {/* Recent Revenue Transactions */}
      <div className="space-y-3">
        <h2 className="text-lg font-bold text-foreground">Recent Revenue</h2>
        {revenueTransactions.length > 0 ? (
          <div className="space-y-2">
            {revenueTransactions.slice(0, 10).map((transaction) => (
              <div
                key={transaction.id}
                className="flex items-center justify-between bg-card rounded-lg p-4 border border-border"
              >
                <div>
                  <p className="font-medium text-foreground">{transaction.description}</p>
                  <p className="text-xs text-muted-foreground">
                    {transaction.paymentMethod} • {transaction.transactionNumber}
                  </p>
                  <p className="text-xs text-muted-foreground">Receipt: {transaction.receiptNumber}</p>
                </div>
                <p className="font-bold text-green-600">+₱{transaction.amount.toLocaleString()}</p>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-muted-foreground">No revenue yet</div>
        )}
      </div>
    </div>
  )
}
