"use client"

import { useState } from "react"
import { Dashboard } from "@/components/dashboard"
import { RevenueComputationPage } from "@/components/pages/revenue-computation-page"
import { TransactionPage } from "@/components/pages/transaction-page"
import { SettingsPage } from "@/components/pages/settings-page"
import { TransactionModal } from "@/components/transaction-modal"
import { BottomNav } from "@/components/bottom-nav"
import { Icons } from "@/components/icons/custom-icons"

export default function Home() {
  const [showModal, setShowModal] = useState(false)
  const [activeTab, setActiveTab] = useState("dashboard")
  const [transactions, setTransactions] = useState([
    {
      id: 1,
      date: "2025-11-09",
      type: "revenue",
      category: "Cash",
      description: "Cash sales",
      amount: 450,
      paymentMethod: "Cash",
      transactionNumber: "TXN001",
      receiptNumber: "RCP001",
      tinNumber: "123-456-789",
      vat: 12,
      supplierName: "Local Supplier",
      supplierAddress: "Manila, PH",
    },
    {
      id: 2,
      date: "2025-11-08",
      type: "revenue",
      category: "GCash",
      description: "GCash payment",
      amount: 280,
      paymentMethod: "GCash",
      transactionNumber: "TXN002",
      receiptNumber: "RCP002",
      tinNumber: "123-456-789",
      vat: 0,
      supplierName: "GCash Partner",
      supplierAddress: "Online",
    },
    {
      id: 3,
      date: "2025-11-08",
      type: "transaction",
      category: "Supplies",
      description: "Coffee beans",
      amount: 150,
      paymentMethod: "Cash",
      transactionNumber: "TXN003",
      receiptNumber: "RCP003",
      tinNumber: "987-654-321",
      vat: 12,
      supplierName: "Coffee Supplier Inc.",
      supplierAddress: "Quezon City, PH",
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
      case "revenue":
        return <RevenueComputationPage transactions={transactions} />
      case "transactions":
        return <TransactionPage transactions={transactions} />
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
        className="fixed bottom-24 right-4 w-14 h-14 rounded-full bg-primary text-primary-foreground shadow-lg flex items-center justify-center hover:bg-primary/90 active:scale-95 transition-transform"
      >
        <Icons.Plus className="w-6 h-6" />
      </button>

      <BottomNav activeTab={activeTab} onTabChange={setActiveTab} />
    </main>
  )
}
