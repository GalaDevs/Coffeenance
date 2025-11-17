"use client"

import { useState } from "react"

const REVENUE_CATEGORIES = ["Cash", "GCash", "Grab", "PayMaya", "Others"]
const TRANSACTION_CATEGORIES = ["Supplies", "Pastries", "Rent", "Utilities", "Manpower", "Marketing", "Others"]
const PAYMENT_METHODS = ["Cash", "Check", "Bank Transfer", "Credit Card", "GCash", "PayMaya", "Others"]

export function TransactionModal({ onClose, onAdd }: any) {
  const [type, setType] = useState<"revenue" | "transaction">("revenue")
  const [category, setCategory] = useState("")
  const [amount, setAmount] = useState("")
  const [description, setDescription] = useState("")
  const [paymentMethod, setPaymentMethod] = useState("")
  const [transactionNumber, setTransactionNumber] = useState("")
  const [receiptNumber, setReceiptNumber] = useState("")
  const [tinNumber, setTinNumber] = useState("")
  const [vat, setVat] = useState("0")
  const [supplierName, setSupplierName] = useState("")
  const [supplierAddress, setSupplierAddress] = useState("")

  const categories = type === "revenue" ? REVENUE_CATEGORIES : TRANSACTION_CATEGORIES

  const handleSubmit = () => {
    if (!category || !amount || !description) {
      alert("Please fill required fields")
      return
    }

    onAdd({
      type,
      category,
      amount: Number.parseFloat(amount),
      description,
      paymentMethod: paymentMethod || category,
      transactionNumber: transactionNumber || `TXN${Date.now()}`,
      receiptNumber: receiptNumber || `RCP${Date.now()}`,
      tinNumber,
      vat: Number.parseInt(vat) || 0,
      supplierName,
      supplierAddress,
    })

    // Reset form
    setType("revenue")
    setCategory("")
    setAmount("")
    setDescription("")
    setPaymentMethod("")
    setTransactionNumber("")
    setReceiptNumber("")
    setTinNumber("")
    setVat("0")
    setSupplierName("")
    setSupplierAddress("")
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-end z-50 animate-in fade-in">
      <div className="w-full bg-card rounded-t-3xl p-6 space-y-4 animate-in slide-in-from-bottom-5 max-h-[90vh] overflow-y-auto">
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
              setType("revenue")
              setCategory("")
            }}
            className={`py-3 rounded-md font-medium transition-all ${
              type === "revenue" ? "bg-primary text-primary-foreground shadow-md" : "text-foreground"
            }`}
          >
            Revenue
          </button>
          <button
            onClick={() => {
              setType("transaction")
              setCategory("")
            }}
            className={`py-3 rounded-md font-medium transition-all ${
              type === "transaction" ? "bg-primary text-primary-foreground shadow-md" : "text-foreground"
            }`}
          >
            Transaction
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
                className={`py-3 px-4 rounded-lg font-medium transition-all border-2 text-sm ${
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
            className="w-full px-4 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary text-sm"
          />
        </div>

        {/* Amount */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">Amount (₱)</label>
          <div className="relative">
            <span className="absolute left-4 top-2.5 text-lg font-semibold text-muted-foreground">₱</span>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0.00"
              className="w-full pl-8 pr-4 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary text-sm"
            />
          </div>
        </div>

        {/* Payment Method */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">Payment Method</label>
          <select
            value={paymentMethod}
            onChange={(e) => setPaymentMethod(e.target.value)}
            className="w-full px-4 py-2 rounded-lg border border-border bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-primary text-sm"
          >
            <option value="">Select payment method</option>
            {PAYMENT_METHODS.map((method) => (
              <option key={method} value={method}>
                {method}
              </option>
            ))}
          </select>
        </div>

        {/* Transaction Number */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">Transaction Number</label>
          <input
            type="text"
            value={transactionNumber}
            onChange={(e) => setTransactionNumber(e.target.value)}
            placeholder="e.g., TXN001"
            className="w-full px-4 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary text-sm"
          />
        </div>

        {/* Official Receipt Number */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">Official Receipt Number</label>
          <input
            type="text"
            value={receiptNumber}
            onChange={(e) => setReceiptNumber(e.target.value)}
            placeholder="e.g., RCP001"
            className="w-full px-4 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary text-sm"
          />
        </div>

        {/* TIN Number */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">TIN Number</label>
          <input
            type="text"
            value={tinNumber}
            onChange={(e) => setTinNumber(e.target.value)}
            placeholder="e.g., 123-456-789"
            className="w-full px-4 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary text-sm"
          />
        </div>

        {/* VAT Selection */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">VAT</label>
          <div className="flex gap-2">
            <button
              onClick={() => setVat("0")}
              className={`flex-1 py-2 rounded-lg font-medium transition-all border-2 text-sm ${
                vat === "0"
                  ? "bg-primary text-primary-foreground border-primary"
                  : "bg-secondary border-border hover:border-primary"
              }`}
            >
              No VAT
            </button>
            <button
              onClick={() => setVat("12")}
              className={`flex-1 py-2 rounded-lg font-medium transition-all border-2 text-sm ${
                vat === "12"
                  ? "bg-primary text-primary-foreground border-primary"
                  : "bg-secondary border-border hover:border-primary"
              }`}
            >
              12% VAT
            </button>
          </div>
        </div>

        {/* Supplier Name */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">Supplier / Vendor Name</label>
          <input
            type="text"
            value={supplierName}
            onChange={(e) => setSupplierName(e.target.value)}
            placeholder="e.g., Coffee Supplier Inc."
            className="w-full px-4 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary text-sm"
          />
        </div>

        {/* Supplier Address */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">Supplier Address</label>
          <input
            type="text"
            value={supplierAddress}
            onChange={(e) => setSupplierAddress(e.target.value)}
            placeholder="e.g., Manila, PH"
            className="w-full px-4 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary text-sm"
          />
        </div>

        {/* Action Buttons */}
        <div className="grid grid-cols-2 gap-3 pt-4 safe-area-inset-bottom">
          <button
            onClick={onClose}
            className="py-3 px-4 rounded-lg border border-border text-foreground font-medium hover:bg-secondary transition-colors text-sm"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            className="py-3 px-4 rounded-lg bg-primary text-primary-foreground font-medium hover:bg-primary/90 transition-colors text-sm"
          >
            Save
          </button>
        </div>
      </div>
    </div>
  )
}
