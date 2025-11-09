export function BalanceCard({ label, amount, income, expense }: any) {
  const isPositive = amount >= 0

  return (
    <div className="rounded-2xl bg-gradient-to-br from-primary to-primary/80 p-6 text-primary-foreground shadow-lg">
      <p className="text-sm opacity-90 mb-2">{label}</p>
      <h2 className="text-4xl font-bold mb-6">
        ₱{isPositive ? "+" : ""}
        {amount.toLocaleString("en-PH", { minimumFractionDigits: 2 })}
      </h2>

      <div className="flex gap-4 text-sm">
        <div className="flex-1">
          <p className="opacity-75 mb-1">Income</p>
          <p className="font-semibold">+₱{income.toLocaleString("en-PH", { minimumFractionDigits: 2 })}</p>
        </div>
        <div className="h-12 w-px bg-primary-foreground/20" />
        <div className="flex-1">
          <p className="opacity-75 mb-1">Expenses</p>
          <p className="font-semibold">-₱{expense.toLocaleString("en-PH", { minimumFractionDigits: 2 })}</p>
        </div>
      </div>
    </div>
  )
}
