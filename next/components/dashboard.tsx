"use client"

import { BalanceCard } from "./balance-card"
import { SalesBreakdown } from "./sales-breakdown"
import { RecentTransactions } from "./recent-transactions"
import { TaxSummary } from "./tax-summary"
import { SalesMonitoring } from "./sales-monitoring"
import { ExpenseBreakdown } from "./expense-breakdown"
import { MoreMenu } from "./more-menu"
import { Button } from "./ui/button"

export function Dashboard({ transactions }: { transactions: any[] }) {
  const incomeTransactions = transactions.filter((t) => t.type === "income")
  const expenseTransactions = transactions.filter((t) => t.type === "expense")

  const totalIncome = incomeTransactions.reduce((sum, t) => sum + t.amount, 0)
  const totalExpense = expenseTransactions.reduce((sum, t) => sum + t.amount, 0)
  const balance = totalIncome - totalExpense

  const salesByMethod = {
    cash: incomeTransactions.filter((t) => t.category === "Cash").reduce((sum, t) => sum + t.amount, 0),
    gcash: incomeTransactions.filter((t) => t.category === "GCash").reduce((sum, t) => sum + t.amount, 0),
    grab: incomeTransactions.filter((t) => t.category === "Grab").reduce((sum, t) => sum + t.amount, 0),
    paymaya: incomeTransactions.filter((t) => t.category === "PayMaya").reduce((sum, t) => sum + t.amount, 0),
  }

  return (
    <div className="px-4 pt-6 pb-4 space-y-6">
      {/* Header with More Menu */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">CoffeeFlow</h1>
          <p className="text-sm text-muted-foreground">Today's Performance</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
            <span className="text-xl">☕</span>
          </div>
          <MoreMenu>
            <div className="space-y-3">
              <div className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                Advanced Reports
              </div>
              <Button variant="ghost" className="w-full justify-start text-sm">
                📊 Monthly P&L Summary
              </Button>
              <Button variant="ghost" className="w-full justify-start text-sm">
                📈 Revenue Trends
              </Button>
              <Button variant="ghost" className="w-full justify-start text-sm">
                💼 Inventory Status
              </Button>
              <Button variant="ghost" className="w-full justify-start text-sm">
                👥 Staff Payroll
              </Button>
              <Button variant="ghost" className="w-full justify-start text-sm">
                🎯 KPI Dashboard
              </Button>
            </div>
          </MoreMenu>
        </div>
      </div>

      {/* Main Balance Card */}
      <BalanceCard label="Today's Balance" amount={balance} income={totalIncome} expense={totalExpense} />

      {/* Tax Summary - Collapsible */}
      <TaxSummary totalIncome={totalIncome} expenses={totalExpense} />

      {/* Sales Monitoring */}
      <SalesMonitoring transactions={transactions} />

      {/* Sales Breakdown */}
      <SalesBreakdown salesByMethod={salesByMethod} totalSales={totalIncome} />

      {/* Expense Breakdown */}
      <ExpenseBreakdown transactions={transactions} />

      {/* Recent Transactions */}
      <RecentTransactions transactions={transactions.slice(0, 5)} />
    </div>
  )
}
