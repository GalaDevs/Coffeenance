export function RecentTransactions({ transactions }: any) {
  const categoryIcons: Record<string, string> = {
    Cash: "💵",
    GCash: "📱",
    Grab: "🚗",
    PayMaya: "💳",
    Supplies: "🛒",
    Rent: "🏠",
    Utilities: "💡",
    Manpower: "👥",
    Marketing: "📢",
    Pastries: "🍰",
  }

  return (
    <div className="space-y-3">
      <h3 className="text-lg font-semibold">Recent Activity</h3>

      <div className="space-y-2">
        {transactions.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            <p className="text-sm">No transactions yet</p>
            <p className="text-xs">Add your first transaction to get started</p>
          </div>
        ) : (
          transactions.map((transaction) => (
            <div
              key={transaction.id}
              className="flex items-center gap-3 p-3 rounded-lg bg-card border border-border hover:bg-secondary transition-colors"
            >
              <div className="text-2xl">{categoryIcons[transaction.category] || "📊"}</div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-foreground truncate">{transaction.description}</p>
                <p className="text-xs text-muted-foreground">
                  {transaction.category} • {transaction.date}
                </p>
              </div>
              <div className="text-right">
                <p
                  className={`font-semibold ${
                    transaction.type === "income"
                      ? "text-green-600 dark:text-green-400"
                      : "text-red-600 dark:text-red-400"
                  }`}
                >
                  {transaction.type === "income" ? "+" : "-"}₱
                  {transaction.amount.toLocaleString("en-PH", {
                    maximumFractionDigits: 0,
                  })}
                </p>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
