"use client"

import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible"
import { ChevronDown } from "lucide-react"

export function TaxSummary({ totalIncome, expenses }: any) {
  const vatRate = 0.12
  const withholdingTax = 0.02

  const grossSales = totalIncome
  const vatTax = grossSales * vatRate
  const withholdingTaxAmount = grossSales * withholdingTax
  const totalTaxes = vatTax + withholdingTaxAmount

  return (
    <Collapsible defaultOpen={false}>
      <CollapsibleTrigger className="w-full flex items-center justify-between rounded-lg bg-card border border-border p-4 hover:bg-card/80 transition">
        <div className="flex items-center gap-3">
          <span className="text-xl">📋</span>
          <span className="text-sm font-semibold text-foreground">Tax Summary</span>
        </div>
        <ChevronDown className="h-4 w-4 text-muted-foreground transition-transform" />
      </CollapsibleTrigger>
      <CollapsibleContent className="mt-2 rounded-lg bg-secondary/50 p-4 space-y-3">
        <div className="flex justify-between items-center text-sm">
          <span className="text-muted-foreground">Gross Sales</span>
          <span className="font-semibold">₱{grossSales.toLocaleString("en-PH", { minimumFractionDigits: 2 })}</span>
        </div>
        <div className="flex justify-between items-center text-sm border-t border-border pt-2">
          <span className="text-muted-foreground">VAT (12%)</span>
          <span className="font-semibold text-destructive">
            -₱{vatTax.toLocaleString("en-PH", { minimumFractionDigits: 2 })}
          </span>
        </div>
        <div className="flex justify-between items-center text-sm">
          <span className="text-muted-foreground">Withholding Tax (2%)</span>
          <span className="font-semibold text-destructive">
            -₱{withholdingTaxAmount.toLocaleString("en-PH", { minimumFractionDigits: 2 })}
          </span>
        </div>
        <div className="flex justify-between items-center text-sm border-t border-border pt-2 bg-destructive/10 px-2 py-1 rounded">
          <span className="font-semibold">Total Taxes</span>
          <span className="font-bold text-destructive">
            -₱{totalTaxes.toLocaleString("en-PH", { minimumFractionDigits: 2 })}
          </span>
        </div>
        <div className="flex justify-between items-center text-sm border-t border-border pt-2">
          <span className="font-semibold text-primary">Net Sales</span>
          <span className="font-bold text-primary">
            ₱{(grossSales - totalTaxes).toLocaleString("en-PH", { minimumFractionDigits: 2 })}
          </span>
        </div>
      </CollapsibleContent>
    </Collapsible>
  )
}
