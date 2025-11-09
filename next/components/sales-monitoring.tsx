"use client"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from "recharts"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"

export function SalesMonitoring({ transactions }: any) {
  const incomeTransactions = transactions.filter((t: any) => t.type === "income")

  // Aggregate sales by method
  const salesByMethod = {
    cash: incomeTransactions
      .filter((t: any) => t.category === "Cash")
      .reduce((sum: number, t: any) => sum + t.amount, 0),
    paymaya: incomeTransactions
      .filter((t: any) => t.category === "PayMaya")
      .reduce((sum: number, t: any) => sum + t.amount, 0),
    gcash: incomeTransactions
      .filter((t: any) => t.category === "GCash")
      .reduce((sum: number, t: any) => sum + t.amount, 0),
    grab: incomeTransactions
      .filter((t: any) => t.category === "Grab")
      .reduce((sum: number, t: any) => sum + t.amount, 0),
  }

  const totalSales = Object.values(salesByMethod).reduce((a: number, b: any) => a + b, 0)

  const chartData = [
    { name: "Cash", value: salesByMethod.cash, fill: "var(--color-chart-1)" },
    { name: "PayMaya", value: salesByMethod.paymaya, fill: "var(--color-chart-2)" },
    { name: "GCash", value: salesByMethod.gcash, fill: "var(--color-chart-3)" },
    { name: "Grab", value: salesByMethod.grab, fill: "var(--color-chart-4)" },
  ]

  return (
    <Card className="border border-border">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg">Sales Monitoring</CardTitle>
        <CardDescription>Payment methods breakdown</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="h-48 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" vertical={false} />
              <XAxis dataKey="name" stroke="var(--color-muted-foreground)" style={{ fontSize: "12px" }} />
              <YAxis stroke="var(--color-muted-foreground)" style={{ fontSize: "12px" }} width={30} />
              <Tooltip
                formatter={(value: any) => `₱${value.toLocaleString("en-PH")}`}
                contentStyle={{
                  backgroundColor: "var(--color-card)",
                  border: `1px solid var(--color-border)`,
                  borderRadius: "8px",
                }}
              />
              <Bar dataKey="value" radius={[8, 8, 0, 0]}>
                {chartData.map((entry: any, index: number) => (
                  <Cell key={`cell-${index}`} fill={entry.fill} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Summary Cards */}
        <div className="space-y-2">
          {chartData.map((method: any) => (
            <div key={method.name} className="flex items-center justify-between rounded-lg bg-secondary/50 p-3">
              <div className="flex items-center gap-2">
                <div className="h-3 w-3 rounded-full" style={{ backgroundColor: method.fill }} />
                <span className="text-sm text-muted-foreground">{method.name}</span>
              </div>
              <span className="font-semibold text-foreground">
                ₱{method.value.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
              </span>
            </div>
          ))}
        </div>

        <div className="border-t border-border pt-3 flex justify-between items-center">
          <span className="font-semibold text-foreground">Total</span>
          <span className="text-lg font-bold text-primary">
            ₱{totalSales.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
          </span>
        </div>
      </CardContent>
    </Card>
  )
}
