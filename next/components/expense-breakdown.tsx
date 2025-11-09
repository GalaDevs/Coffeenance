"use client"

import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from "recharts"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"

export function ExpenseBreakdown({ transactions }: any) {
  const expenseTransactions = transactions.filter((t: any) => t.type === "expense")

  // Aggregate by category
  const expensesByCategory = expenseTransactions.reduce((acc: any, t: any) => {
    const existing = acc.find((e: any) => e.category === t.category)
    if (existing) {
      existing.value += t.amount
    } else {
      acc.push({ category: t.category, value: t.amount })
    }
    return acc
  }, [])

  const totalExpenses = expenseTransactions.reduce((sum: number, t: any) => sum + t.amount, 0)

  const colors = [
    "var(--color-chart-1)",
    "var(--color-chart-2)",
    "var(--color-chart-3)",
    "var(--color-chart-4)",
    "var(--color-chart-5)",
  ]

  const chartData = expensesByCategory.map((item: any, index: number) => ({
    ...item,
    fill: colors[index % colors.length],
  }))

  return (
    <Card className="border border-border">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg">Expense Breakdown</CardTitle>
        <CardDescription>By category</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {chartData.length > 0 ? (
          <>
            <div className="h-48 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={chartData}
                    dataKey="value"
                    nameKey="category"
                    cx="50%"
                    cy="50%"
                    outerRadius={60}
                    label={false}
                  >
                    {chartData.map((entry: any, index: number) => (
                      <Cell key={`cell-${index}`} fill={entry.fill} />
                    ))}
                  </Pie>
                  <Tooltip
                    formatter={(value: any) => `₱${value.toLocaleString("en-PH")}`}
                    contentStyle={{
                      backgroundColor: "var(--color-card)",
                      border: `1px solid var(--color-border)`,
                      borderRadius: "8px",
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>

            <div className="space-y-2">
              {chartData.map((item: any) => {
                const percentage = ((item.value / totalExpenses) * 100).toFixed(1)
                return (
                  <div key={item.category} className="flex items-center justify-between rounded-lg bg-secondary/50 p-3">
                    <div className="flex items-center gap-2">
                      <div className="h-3 w-3 rounded-full" style={{ backgroundColor: item.fill }} />
                      <span className="text-sm text-muted-foreground">{item.category}</span>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-semibold">
                        ₱{item.value.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
                      </div>
                      <div className="text-xs text-muted-foreground">{percentage}%</div>
                    </div>
                  </div>
                )
              })}
            </div>

            <div className="border-t border-border pt-3 flex justify-between items-center">
              <span className="font-semibold text-foreground">Total Expenses</span>
              <span className="text-lg font-bold text-destructive">
                -₱{totalExpenses.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
              </span>
            </div>
          </>
        ) : (
          <div className="py-6 text-center text-muted-foreground">No expense data</div>
        )}
      </CardContent>
    </Card>
  )
}
