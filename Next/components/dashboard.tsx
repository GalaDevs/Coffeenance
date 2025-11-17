"use client"

import { BalanceCard } from "./balance-card"
import { SalesBreakdown } from "./sales-breakdown"
import { RecentTransactions } from "./recent-transactions"
import { TaxSummary } from "./tax-summary"
import { SalesMonitoring } from "./sales-monitoring"
import { ExpenseBreakdown } from "./expense-breakdown"
import { MoreMenu } from "./more-menu"
import { Button } from "./ui/button"
import { Icons } from "./icons/custom-icons"

export function Dashboard({ transactions }: { transactions: any[] }) {
  const revenueTransactions = transactions.filter((t) => t.type === "revenue")
  const transactionExpenses = transactions.filter((t) => t.type === "transaction")

  const totalRevenue = revenueTransactions.reduce((sum, t) => sum + t.amount, 0)
  const totalExpense = transactionExpenses.reduce((sum, t) => sum + t.amount, 0)
  const balance = totalRevenue - totalExpense

  const salesByMethod = {
    cash: revenueTransactions.filter((t) => t.paymentMethod === "Cash").reduce((sum, t) => sum + t.amount, 0),
    gcash: revenueTransactions.filter((t) => t.paymentMethod === "GCash").reduce((sum, t) => sum + t.amount, 0),
    grab: revenueTransactions.filter((t) => t.paymentMethod === "Grab").reduce((sum, t) => sum + t.amount, 0),
    paymaya: revenueTransactions.filter((t) => t.paymentMethod === "PayMaya").reduce((sum, t) => sum + t.amount, 0),
    others: revenueTransactions.filter((t) => t.paymentMethod === "Others").reduce((sum, t) => sum + t.amount, 0),
  }

  return (
    <div className="px-4 pt-6 pb-4 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">CoffeeFlow</h1>
          <p className="text-sm text-muted-foreground">Today's Performance</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
            <Icons.TrendUp className="w-6 h-6 text-primary" />
          </div>
          <MoreMenu>
            <div className="space-y-3">
              <div className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                Advanced Reports
              </div>
              <Button variant="ghost" className="w-full justify-start text-sm gap-2">
                <Icons.TrendUp className="w-4 h-4" />
                Monthly P&L Summary
              </Button>
              <Button variant="ghost" className="w-full justify-start text-sm gap-2">
                <Icons.Sales className="w-4 h-4" />
                Revenue Trends
              </Button>
              <Button variant="ghost" className="w-full justify-start text-sm gap-2">
                <Icons.Dashboard className="w-4 h-4" />
                Inventory Status
              </Button>
              <Button variant="ghost" className="w-full justify-start text-sm gap-2">
                <Icons.Income className="w-4 h-4" />
                Staff Payroll
              </Button>
              <Button variant="ghost" className="w-full justify-start text-sm gap-2">
                <Icons.Dashboard className="w-4 h-4" />
                KPI Dashboard
              </Button>
            </div>
          </MoreMenu>
        </div>
      </div>

      {/* Main Balance Card */}
      <BalanceCard label="Today's Balance" amount={balance} income={totalRevenue} expense={totalExpense} />

      {/* Tax Summary - Collapsible */}
      <TaxSummary totalIncome={totalRevenue} expenses={totalExpense} />

      {/* Sales Monitoring */}
      <SalesMonitoring transactions={transactions} />

      {/* Sales Breakdown */}
      <SalesBreakdown salesByMethod={salesByMethod} totalSales={totalRevenue} />

      {/* Expense Breakdown */}
      <ExpenseBreakdown transactions={transactions} />

      {/* Recent Transactions */}
      <RecentTransactions transactions={transactions.slice(0, 5)} />
    </div>
  )
}
