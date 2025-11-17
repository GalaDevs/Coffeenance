"use client"

import type React from "react"
import { useState } from "react"

import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet"
import { Button } from "@/components/ui/button"
import { MoreVertical } from "lucide-react"
import { MonthlyPLModal } from "./modals/monthly-pl-modal"
import { RevenueTrendsModal } from "./modals/revenue-trends-modal"
import { InventoryModal } from "./modals/inventory-modal"
import { PayrollModal } from "./modals/payroll-modal"
import { KPIModal } from "./modals/kpi-modal"

export function MoreMenu({ children }: { children: React.ReactNode }) {
  const [plOpen, setPLOpen] = useState(false)
  const [trendsOpen, setTrendsOpen] = useState(false)
  const [inventoryOpen, setInventoryOpen] = useState(false)
  const [payrollOpen, setPayrollOpen] = useState(false)
  const [kpiOpen, setKPIOpen] = useState(false)
  const [sheetOpen, setSheetOpen] = useState(false)

  const handleMenuClick = (modalSetter: React.Dispatch<React.SetStateAction<boolean>>) => {
    setSheetOpen(false)
    modalSetter(true)
  }

  return (
    <>
      <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
        <SheetTrigger asChild>
          <Button variant="outline" size="icon" className="rounded-lg bg-transparent">
            <MoreVertical className="h-4 w-4" />
          </Button>
        </SheetTrigger>
        <SheetContent side="bottom" className="rounded-t-2xl">
          <SheetHeader>
            <SheetTitle>Additional Reports</SheetTitle>
            <SheetDescription>Less frequently used metrics and advanced features</SheetDescription>
          </SheetHeader>
          <div className="mt-6 space-y-3 pb-6">
            <Button variant="ghost" className="w-full justify-start text-sm" onClick={() => handleMenuClick(setPLOpen)}>
              📊 Monthly P&L Summary
            </Button>
            <Button
              variant="ghost"
              className="w-full justify-start text-sm"
              onClick={() => handleMenuClick(setTrendsOpen)}
            >
              📈 Revenue Trends
            </Button>
            <Button
              variant="ghost"
              className="w-full justify-start text-sm"
              onClick={() => handleMenuClick(setInventoryOpen)}
            >
              💼 Inventory Status
            </Button>
            <Button
              variant="ghost"
              className="w-full justify-start text-sm"
              onClick={() => handleMenuClick(setPayrollOpen)}
            >
              👥 Staff Payroll
            </Button>
            <Button
              variant="ghost"
              className="w-full justify-start text-sm"
              onClick={() => handleMenuClick(setKPIOpen)}
            >
              🎯 KPI Dashboard
            </Button>
          </div>
        </SheetContent>
      </Sheet>

      {/* Modals */}
      <MonthlyPLModal open={plOpen} onOpenChange={setPLOpen} />
      <RevenueTrendsModal open={trendsOpen} onOpenChange={setTrendsOpen} />
      <InventoryModal open={inventoryOpen} onOpenChange={setInventoryOpen} />
      <PayrollModal open={payrollOpen} onOpenChange={setPayrollOpen} />
      <KPIModal open={kpiOpen} onOpenChange={setKPIOpen} />
    </>
  )
}
