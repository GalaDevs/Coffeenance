"use client"

import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts"

const inventoryData = [
  { item: "Coffee Beans", stock: 45, unit: "kg", status: "good", reorder: 30 },
  { item: "Milk", stock: 12, unit: "L", status: "warning", reorder: 20 },
  { item: "Sugar", stock: 8, unit: "kg", status: "critical", reorder: 15 },
  { item: "Pastry Dough", stock: 25, unit: "kg", status: "good", reorder: 20 },
  { item: "Cups (12oz)", stock: 200, unit: "pcs", status: "good", reorder: 500 },
  { item: "Napkins", stock: 80, unit: "pcs", status: "warning", reorder: 200 },
]

const consumptionData = [
  { item: "Coffee Beans", daily: 2.5 },
  { item: "Milk", daily: 1.2 },
  { item: "Sugar", daily: 0.8 },
  { item: "Cups", daily: 150 },
]

export function InventoryModal({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const getStatusColor = (status: string) => {
    switch (status) {
      case "good":
        return "bg-green-100 text-green-800"
      case "warning":
        return "bg-yellow-100 text-yellow-800"
      case "critical":
        return "bg-red-100 text-red-800"
      default:
        return "bg-gray-100 text-gray-800"
    }
  }

  const criticalItems = inventoryData.filter((i) => i.status === "critical").length
  const lowItems = inventoryData.filter((i) => i.status === "warning").length

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Inventory Status</DialogTitle>
          <DialogDescription>Current stock levels and reorder recommendations</DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Status Summary */}
          <div className="grid grid-cols-3 gap-3">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Total Items</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{inventoryData.length}</div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Critical Items</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-red-600">{criticalItems}</div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Low Stock</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-yellow-600">{lowItems}</div>
              </CardContent>
            </Card>
          </div>

          {/* Daily Consumption */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Daily Consumption</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={250}>
                <BarChart data={consumptionData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="item" angle={-45} textAnchor="end" height={80} />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="daily" fill="#3b82f6" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Inventory Table */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Stock Levels</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {inventoryData.map((item) => (
                  <div key={item.item} className="flex items-center justify-between p-3 border rounded-lg">
                    <div className="flex-1">
                      <p className="font-medium text-sm">{item.item}</p>
                      <p className="text-xs text-muted-foreground">
                        Stock: {item.stock} {item.unit} | Reorder: {item.reorder} {item.unit}
                      </p>
                    </div>
                    <Badge className={getStatusColor(item.status)}>{item.status.toUpperCase()}</Badge>
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
