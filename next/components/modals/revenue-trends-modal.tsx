"use client"

import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

const revenueData = [
  { date: "Mon", sales: 12000, target: 15000 },
  { date: "Tue", sales: 14500, target: 15000 },
  { date: "Wed", sales: 13200, target: 15000 },
  { date: "Thu", sales: 15800, target: 15000 },
  { date: "Fri", sales: 18200, target: 15000 },
  { date: "Sat", sales: 22000, target: 15000 },
  { date: "Sun", sales: 19500, target: 15000 },
]

const categoryData = [
  { category: "Coffee", revenue: 45000, trend: 12 },
  { category: "Pastries", revenue: 28000, trend: 8 },
  { category: "Snacks", revenue: 15000, trend: -2 },
  { category: "Beverages", revenue: 32000, trend: 15 },
]

export function RevenueTrendsModal({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const avgDaily = (revenueData.reduce((sum, d) => sum + d.sales, 0) / revenueData.length).toFixed(0)
  const weeklyTotal = revenueData.reduce((sum, d) => sum + d.sales, 0)

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Revenue Trends</DialogTitle>
          <DialogDescription>Weekly sales performance and category analysis</DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* KPI Cards */}
          <div className="grid grid-cols-2 gap-3">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Weekly Total</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-green-600">₱{(weeklyTotal / 1000).toFixed(0)}K</div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Daily Average</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-blue-600">₱{avgDaily}</div>
              </CardContent>
            </Card>
          </div>

          {/* Daily Trend */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Daily Sales vs Target</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={revenueData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Area type="monotone" dataKey="sales" fill="#10b981" stroke="#10b981" name="Actual Sales" />
                  <Area type="monotone" dataKey="target" fill="#f3f4f6" stroke="#6b7280" name="Target" opacity={0.5} />
                </AreaChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Category Breakdown */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Revenue by Category</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {categoryData.map((item) => (
                  <div key={item.category} className="flex items-center justify-between p-3 bg-muted/50 rounded">
                    <div>
                      <p className="font-medium text-sm">{item.category}</p>
                      <p className="text-xs text-muted-foreground">₱{item.revenue.toLocaleString()}</p>
                    </div>
                    <div className={`text-sm font-semibold ${item.trend > 0 ? "text-green-600" : "text-red-600"}`}>
                      {item.trend > 0 ? "+" : ""}
                      {item.trend}%
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </DialogContent>
    </Dialog>
  )
}
