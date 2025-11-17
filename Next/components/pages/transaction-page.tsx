"use client"

export function TransactionPage({ transactions }: { transactions: any[] }) {
  const expenseTransactions = transactions.filter((t) => t.type === "transaction")

  const totalExpenses = expenseTransactions.reduce((sum, t) => sum + t.amount, 0)

  const expensesByCategory = {
    Supplies: expenseTransactions.filter((t) => t.category === "Supplies").reduce((sum, t) => sum + t.amount, 0),
    Pastries: expenseTransactions.filter((t) => t.category === "Pastries").reduce((sum, t) => sum + t.amount, 0),
    Rent: expenseTransactions.filter((t) => t.category === "Rent").reduce((sum, t) => sum + t.amount, 0),
    Utilities: expenseTransactions.filter((t) => t.category === "Utilities").reduce((sum, t) => sum + t.amount, 0),
    Manpower: expenseTransactions.filter((t) => t.category === "Manpower").reduce((sum, t) => sum + t.amount, 0),
    Marketing: expenseTransactions.filter((t) => t.category === "Marketing").reduce((sum, t) => sum + t.amount, 0),
    Others: expenseTransactions.filter((t) => t.category === "Others").reduce((sum, t) => sum + t.amount, 0),
  }

  const expenseData = Object.entries(expensesByCategory)
    .filter(([_, amount]) => amount > 0)
    .map(([category, amount]) => ({
      category,
      amount,
      percentage: Math.round((amount / totalExpenses) * 100) || 0,
    }))
    .sort((a, b) => b.amount - a.amount)

  return (
    <div className="px-4 pt-6 pb-4 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Transactions</h1>
          <p className="text-sm text-muted-foreground">Expense breakdown by category</p>
        </div>
      </div>

      {/* Total Transactions Card */}
      <div className="bg-gradient-to-br from-red-600 to-red-700 rounded-2xl p-6 text-white shadow-lg">
        <p className="text-sm font-medium opacity-90">Total Expenses</p>
        <p className="text-4xl font-bold mt-2">₱{totalExpenses.toLocaleString()}</p>
        <p className="text-xs mt-3 opacity-75">{expenseTransactions.length} transactions</p>
      </div>

      {/* Expenses by Category */}
      <div className="space-y-3">
        <h2 className="text-lg font-bold text-foreground">By Category</h2>
        {expenseData.length > 0 ? (
          expenseData.map((item) => (
            <div key={item.category} className="bg-card rounded-lg p-4 border border-border">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium text-foreground">{item.category}</span>
                <span className="text-sm font-bold text-red-600">₱{item.amount.toLocaleString()}</span>
              </div>
              <div className="w-full bg-secondary rounded-full h-2 overflow-hidden">
                <div
                  className="bg-gradient-to-r from-red-500 to-red-600 h-full transition-all"
                  style={{ width: `${item.percentage}%` }}
                />
              </div>
              <div className="text-xs text-muted-foreground mt-1">{item.percentage}% of expenses</div>
            </div>
          ))
        ) : (
          <div className="text-center py-8 text-muted-foreground">No expenses recorded yet</div>
        )}
      </div>

      {/* Recent Transactions */}
      <div className="space-y-3">
        <h2 className="text-lg font-bold text-foreground">Recent Transactions</h2>
        {expenseTransactions.length > 0 ? (
          <div className="space-y-2">
            {expenseTransactions.slice(0, 10).map((transaction) => (
              <div
                key={transaction.id}
                className="flex items-center justify-between bg-card rounded-lg p-4 border border-border"
              >
                <div>
                  <p className="font-medium text-foreground">{transaction.description}</p>
                  <p className="text-xs text-muted-foreground">{transaction.category}</p>
                  <p className="text-xs text-muted-foreground">
                    {transaction.supplierName} • TIN: {transaction.tinNumber}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Voucher: {transaction.transactionNumber} • Receipt: {transaction.receiptNumber}
                  </p>
                  {transaction.vat > 0 && (
                    <p className="text-xs text-muted-foreground">VAT: {transaction.vat}%</p>
                  )}
                </div>
                <p className="font-bold text-red-600">-₱{transaction.amount.toLocaleString()}</p>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-muted-foreground">No transactions yet</div>
        )}
      </div>
    </div>
  )
}
