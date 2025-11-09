"use client"

import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from "recharts"

const staffData = [
  { id: 1, name: "Maria Santos", position: "Manager", salary: 25000, status: "Full-time", startDate: "2023-01" },
  { id: 2, name: "Juan Dela Cruz", position: "Barista", salary: 18000, status: "Full-time", startDate: "2023-06" },
  { id: 3, name: "Rosa Garcia", position: "Cashier", salary: 16000, status: "Full-time", startDate: "2023-09" },
  { id: 4, name: "Pedro Lim", position: "Barista", salary: 18000, status: "Full-time", startDate: "2024-01" },
  { id: 5, name: "Anna Wong", position: "Part-time Staff", salary: 12000, status: "Part-time", startDate: "2024-03" },
]

const payrollSummary = [
  { name: "Salaries", value: 89000, color: "#3b82f6" },
  { name: "Benefits", value: 12000, color: "#10b981" },
  { name: "Contributions", value: 8000, color: "#f59e0b" },
]

export function PayrollModal({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const totalPayroll = staffData.reduce((sum, s) => sum + s.salary, 0)
  const staffCount = staffData.length
  const avgSalary = (totalPayroll / staffCount).toFixed(0)

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Staff Payroll</DialogTitle>
          <DialogDescription>Employee roster and salary information</DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Summary Cards */}
          <div className="grid grid-cols-3 gap-3">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Total Staff</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{staffCount}</div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Monthly Payroll</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-blue-600">₱{(totalPayroll / 1000).toFixed(0)}K</div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Average Salary</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">₱{avgSalary}</div>
              </CardContent>
            </Card>
          </div>

          {/* Payroll Breakdown */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Payroll Composition</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={250}>
                <PieChart>
                  <Pie
                    data={payrollSummary}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, value }) => `${name}: ₱${value.toLocaleString()}`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {payrollSummary.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value) => `₱${value.toLocaleString()}`} />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Staff List */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Staff Directory</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {staffData.map((staff) => (
                  <div key={staff.id} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg border">
                    <div className="flex-1">
                      <p className="font-medium text-sm">{staff.name}</p>
                      <p className="text-xs text-muted-foreground">
                        {staff.position} • {staff.status} • Since {staff.startDate}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="font-semibold text-sm">₱{staff.salary.toLocaleString()}</p>
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
