"use client"

import { useState } from "react"
import { Dashboard } from "@/components/dashboard"
import { SalesPage } from "@/components/pages/sales-page"
import { ExpensesPage } from "@/components/pages/expenses-page"
import { SettingsPage } from "@/components/pages/settings-page"
import { TransactionModal } from "@/components/transaction-modal"
import { BottomNav } from "@/components/bottom-nav"

export default function Home() {
  const [showModal, setShowModal] = useState(false)
  const [activeTab, setActiveTab] = useState("dashboard")
  const [transactions, setTransactions] = useState([
    {
      id: 1,
      date: "2025-11-09",
      type: "income",
      category: "Cash",
      description: "Cash sales",
      amount: 450,
    },
    {
      id: 2,
      date: "2025-11-08",
      type: "income",
      category: "GCash",
      description: "GCash payment",
      amount: 280,
    },
    {
      id: 3,
      date: "2025-11-08",
      type: "expense",
      category: "Supplies",
      description: "Coffee beans",
      amount: 150,
    },
  ])

  const handleAddTransaction = (transaction: any) => {
    setTransactions([
      {
        id: transactions.length + 1,
        ...transaction,
        date: new Date().toISOString().split("T")[0],
      },
      ...transactions,
    ])
    setShowModal(false)
  }

  const renderContent = () => {
    switch (activeTab) {
      case "dashboard":
        return <Dashboard transactions={transactions} />
      case "sales":
        return <SalesPage transactions={transactions} />
      case "expenses":
        return <ExpensesPage transactions={transactions} />
      case "settings":
        return <SettingsPage />
      default:
        return <Dashboard transactions={transactions} />
    }
  }

  return (
    <main className="pb-20 min-h-screen bg-background">
      {renderContent()}

      {showModal && <TransactionModal onClose={() => setShowModal(false)} onAdd={handleAddTransaction} />}

      <button
        onClick={() => setShowModal(true)}
        className="fixed bottom-24 right-4 w-14 h-14 rounded-full bg-primary text-primary-foreground shadow-lg flex items-center justify-center text-2xl hover:bg-primary/90 active:scale-95 transition-transform"
      >
        +
      </button>

      <BottomNav activeTab={activeTab} onTabChange={setActiveTab} />
    </main>
  )
}
