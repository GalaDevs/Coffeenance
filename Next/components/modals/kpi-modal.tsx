"use client"

import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  Radar,
} from "recharts"

const kpiTrends = [
  { week: "W1", satisfaction: 85, efficiency: 78, retention: 92 },
  { week: "W2", satisfaction: 87, efficiency: 82, retention: 93 },
  { week: "W3", satisfaction: 89, efficiency: 85, retention: 94 },
  { week: "W4", satisfaction: 91, efficiency: 88, retention: 95 },
]

const performanceRadar = [
  { metric: "Customer Satisfaction", value: 91 },
  { metric: "Operational Efficiency", value: 88 },
  { metric: "Staff Retention", value: 95 },
  { metric: "Inventory Turnover", value: 82 },
  { metric: "Revenue Growth", value: 78 },
]

const kpiCards = [
  { label: "Customer Satisfaction", value: "91%", target: "95%", status: "on-track" },
  { label: "Daily Transactions", value: "324", target: "300", status: "above-target" },
  { label: "Average Transaction", value: "₱580", target: "₱600", status: "on-track" },
  { label: "Staff Efficiency", value: "88%", target: "85%", status: "above-target" },
]

export function KPIModal({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>KPI Dashboard</DialogTitle>
          <DialogDescription>Key performance indicators and business metrics</DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* KPI Cards */}
          <div className="grid grid-cols-2 gap-3">
            {kpiCards.map((kpi) => (
              <Card key={kpi.label}>
                <CardHeader className="pb-2">
                  <CardTitle className="text-xs font-medium text-muted-foreground">{kpi.label}</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="flex items-end justify-between">
                    <div>
                      <div className="text-2xl font-bold">{kpi.value}</div>
                      <p className="text-xs text-muted-foreground">Target: {kpi.target}</p>
                    </div>
                    <div
                      className={`text-xs font-semibold px-2 py-1 rounded ${kpi.status === "above-target" ? "bg-green-100 text-green-800" : "bg-blue-100 text-blue-800"}`}
                    >
                      {kpi.status === "above-target" ? "✓ Above" : "◔ On Track"}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Performance Radar */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Performance Score</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <RadarChart data={performanceRadar}>
                  <PolarGrid />
                  <PolarAngleAxis dataKey="metric" />
                  <PolarRadiusAxis angle={90} domain={[0, 100]} />
                  <Radar name="Performance" dataKey="value" stroke="#3b82f6" fill="#3b82f6" fillOpacity={0.6} />
                  <Tooltip />
                </RadarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* KPI Trends */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Weekly Trends</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={kpiTrends}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="week" />
                  <YAxis domain={[0, 100]} />
                  <Tooltip />
                  <Legend />
                  <Line
                    type="monotone"
                    dataKey="satisfaction"
                    stroke="#10b981"
                    name="Customer Satisfaction"
                    strokeWidth={2}
                  />
                  <Line
                    type="monotone"
                    dataKey="efficiency"
                    stroke="#3b82f6"
                    name="Operational Efficiency"
                    strokeWidth={2}
                  />
                  <Line type="monotone" dataKey="retention" stroke="#f59e0b" name="Staff Retention" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>
      </DialogContent>
    </Dialog>
  )
}
