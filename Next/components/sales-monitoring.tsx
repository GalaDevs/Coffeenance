"use client"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from "recharts"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Icons } from "@/components/icons/custom-icons"

export function SalesMonitoring({ transactions }: any) {
  const incomeTransactions = transactions.filter((t: any) => t.type === "income")

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

  const methodIcons: Record<string, any> = {
    Cash: <Icons.Wallet className="w-5 h-5" />,
    PayMaya: <Icons.CreditCard className="w-5 h-5" />,
    GCash: <Icons.Mobile className="w-5 h-5" />,
    Grab: <Icons.TrendUp className="w-5 h-5" />,
  }

  const chartData = [
    { name: "Cash", value: salesByMethod.cash, fill: "var(--color-chart-1)" },
    { name: "PayMaya", value: salesByMethod.paymaya, fill: "var(--color-chart-2)" },
    { name: "GCash", value: salesByMethod.gcash, fill: "var(--color-chart-3)" },
    { name: "Grab", value: salesByMethod.grab, fill: "var(--color-chart-4)" },
  ]

  return (
    <Card className="border border-border bg-gradient-to-br from-card to-card/50">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg flex items-center gap-2">
          <Icons.Sales className="w-5 h-5 text-primary" />
          Sales Monitoring
        </CardTitle>
        <CardDescription>Payment methods breakdown</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="h-56 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" vertical={false} />
              <XAxis dataKey="name" stroke="var(--color-muted-foreground)" style={{ fontSize: "12px" }} />
              <YAxis stroke="var(--color-muted-foreground)" style={{ fontSize: "12px" }} width={30} />
              <Tooltip
                formatter={(value: any) => `₱${value.toLocaleString("en-PH")}`}
                contentStyle={{
                  backgroundColor: "var(--color-card)",
                  border: `2px solid var(--color-primary)`,
                  borderRadius: "12px",
                  boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
                }}
                cursor={{ fill: "rgba(139, 92, 246, 0.1)" }}
              />
              <Bar dataKey="value" radius={[12, 12, 0, 0]}>
                {chartData.map((entry: any, index: number) => (
                  <Cell key={`cell-${index}`} fill={entry.fill} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="grid grid-cols-2 gap-2">
          {chartData.map((method: any) => (
            <div
              key={method.name}
              className="group rounded-lg bg-secondary/50 hover:bg-secondary/80 p-3 transition-all hover:shadow-md"
            >
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <div className="p-1.5 rounded-lg bg-primary/10">
                    {methodIcons[method.name] || <Icons.Wallet className="w-4 h-4 text-primary" />}
                  </div>
                  <span className="text-xs font-medium text-muted-foreground">{method.name}</span>
                </div>
              </div>
              <span className="font-semibold text-foreground text-sm">
                ₱{method.value.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
              </span>
              <div className="mt-1.5 h-1 bg-secondary rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full transition-all"
                  style={{
                    backgroundColor: method.fill,
                    width: `${totalSales > 0 ? (method.value / totalSales) * 100 : 0}%`,
                  }}
                />
              </div>
            </div>
          ))}
        </div>

        <div className="border-t border-border pt-3 flex justify-between items-center bg-primary/5 rounded-lg p-3 -mx-6 px-6">
          <span className="font-semibold text-foreground">Total Sales</span>
          <span className="text-lg font-bold text-primary">
            ₱{totalSales.toLocaleString("en-PH", { maximumFractionDigits: 0 })}
          </span>
        </div>
      </CardContent>
    </Card>
  )
}
