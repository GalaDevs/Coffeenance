"use client"

import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from "recharts"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Icons } from "@/components/icons/custom-icons"

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
    <Card className="border border-border bg-gradient-to-br from-card to-card/50">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg flex items-center gap-2">
          <Icons.TrendDown className="w-5 h-5 text-destructive" />
          Expense Breakdown
        </CardTitle>
        <CardDescription>By category</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {chartData.length > 0 ? (
          <>
            <div className="h-56 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={chartData}
                    dataKey="value"
                    nameKey="category"
                    cx="50%"
                    cy="50%"
                    outerRadius={70}
                    innerRadius={40}
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
                      border: `2px solid var(--color-destructive)`,
                      borderRadius: "12px",
                      boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>

            <div className="grid grid-cols-1 gap-2">
              {chartData.map((item: any) => {
                const percentage = ((item.value / totalExpenses) * 100).toFixed(1)
                return (
                  <div
                    key={item.category}
                    className="group flex items-center justify-between rounded-lg bg-secondary/50 hover:bg-secondary/80 p-3 transition-all hover:shadow-md"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="h-3 w-3 rounded-full flex-shrink-0" style={{ backgroundColor: item.fill }} />
                      <div className="min-w-0">
                        <p className="text-sm font-medium text-foreground truncate">{item.category}</p>
                        <p className="text-xs text-muted-foreground">{percentage}%</p>
                      </div>
                    </div>
                    <div className="text-right flex-shrink-0 ml-2">
                      <div className="text-sm font-semibold text-foreground">
                        ₱{item.value.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>

            <div className="border-t border-border pt-3 flex justify-between items-center bg-destructive/5 rounded-lg p-3 -mx-6 px-6">
              <span className="font-semibold text-foreground">Total Expenses</span>
              <span className="text-lg font-bold text-destructive">
                -₱{totalExpenses.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
              </span>
            </div>
          </>
        ) : (
          <div className="py-8 text-center">
            <Icons.Dashboard className="w-12 h-12 text-muted-foreground/50 mx-auto mb-2" />
            <p className="text-muted-foreground">No expense data</p>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
