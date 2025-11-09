"use client"

import { useState } from "react"

const INCOME_CATEGORIES = ["Cash", "GCash", "Grab", "PayMaya"]
const EXPENSE_CATEGORIES = ["Supplies", "Pastries", "Rent", "Utilities", "Manpower", "Marketing", "Others"]

export function TransactionModal({ onClose, onAdd }: any) {
  const [type, setType] = useState<"income" | "expense">("income")
  const [category, setCategory] = useState("")
  const [amount, setAmount] = useState("")
  const [description, setDescription] = useState("")

  const categories = type === "income" ? INCOME_CATEGORIES : EXPENSE_CATEGORIES

  const handleSubmit = () => {
    if (!category || !amount || !description) {
      alert("Please fill all fields")
      return
    }

    onAdd({
      type,
      category,
      amount: Number.parseFloat(amount),
      description,
    })

    setType("income")
    setCategory("")
    setAmount("")
    setDescription("")
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-end z-50 animate-in fade-in">
      <div className="w-full bg-card rounded-t-3xl p-6 space-y-6 animate-in slide-in-from-bottom-5 max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold">Add Transaction</h2>
          <button onClick={onClose} className="text-2xl text-muted-foreground hover:text-foreground">
            ✕
          </button>
        </div>

        {/* Type Toggle */}
        <div className="grid grid-cols-2 gap-3 bg-secondary rounded-lg p-1">
          <button
            onClick={() => {
              setType("income")
              setCategory("")
            }}
            className={`py-3 rounded-md font-medium transition-all ${
              type === "income" ? "bg-primary text-primary-foreground shadow-md" : "text-foreground"
            }`}
          >
            Income
          </button>
          <button
            onClick={() => {
              setType("expense")
              setCategory("")
            }}
            className={`py-3 rounded-md font-medium transition-all ${
              type === "expense" ? "bg-primary text-primary-foreground shadow-md" : "text-foreground"
            }`}
          >
            Expense
          </button>
        </div>

        {/* Category Selection */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-3">Category</label>
          <div className="grid grid-cols-2 gap-2">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setCategory(cat)}
                className={`py-3 px-4 rounded-lg font-medium transition-all border-2 ${
                  category === cat
                    ? "bg-primary text-primary-foreground border-primary"
                    : "bg-secondary border-border hover:border-primary"
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>

        {/* Description */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">Description</label>
          <input
            type="text"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="e.g., Morning sales"
            className="w-full px-4 py-3 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>

        {/* Amount */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">Amount (₱)</label>
          <div className="relative">
            <span className="absolute left-4 top-3.5 text-lg font-semibold text-muted-foreground">₱</span>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0.00"
              className="w-full pl-8 pr-4 py-3 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary text-lg"
            />
          </div>
        </div>

        {/* Action Buttons */}
        <div className="grid grid-cols-2 gap-3 pt-4 safe-area-inset-bottom">
          <button
            onClick={onClose}
            className="py-3 px-4 rounded-lg border border-border text-foreground font-medium hover:bg-secondary transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            className="py-3 px-4 rounded-lg bg-primary text-primary-foreground font-medium hover:bg-primary/90 transition-colors"
          >
            Save
          </button>
        </div>
      </div>
    </div>
  )
}
