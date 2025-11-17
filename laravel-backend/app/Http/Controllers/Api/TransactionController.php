<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTransactionRequest;
use App\Http\Requests\UpdateTransactionRequest;
use App\Http\Resources\TransactionResource;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

/**
 * Transaction API Controller
 * Matches Next.js transaction logic and formulas
 */
class TransactionController extends Controller
{
    /**
     * Display a listing of transactions.
     * Supports filtering by type, category, date range
     */
    public function index(Request $request)
    {
        $query = Transaction::query();

        // Filter by type (revenue or transaction)
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        // Filter by category
        if ($request->has('category')) {
            $query->where('category', $request->category);
        }

        // Filter by date range
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->dateRange($request->start_date, $request->end_date);
        }

        // Order by date descending (newest first)
        $query->orderBy('date', 'desc')->orderBy('created_at', 'desc');

        // Paginate if requested
        if ($request->has('per_page')) {
            $transactions = $query->paginate($request->per_page);
            return TransactionResource::collection($transactions);
        }

        // Otherwise return all
        $transactions = $query->get();
        return TransactionResource::collection($transactions);
    }

    /**
     * Store a newly created transaction.
     * Matches Next.js handleSubmit logic
     */
    public function store(StoreTransactionRequest $request)
    {
        $transaction = Transaction::create($request->validated());

        return (new TransactionResource($transaction))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    /**
     * Display the specified transaction.
     */
    public function show(Transaction $transaction)
    {
        return new TransactionResource($transaction);
    }

    /**
     * Update the specified transaction.
     */
    public function update(UpdateTransactionRequest $request, Transaction $transaction)
    {
        $transaction->update($request->validated());

        return new TransactionResource($transaction);
    }

    /**
     * Remove the specified transaction.
     */
    public function destroy(Transaction $transaction)
    {
        $transaction->delete();

        return response()->json([
            'message' => 'Transaction deleted successfully',
        ], Response::HTTP_OK);
    }

    /**
     * Get dashboard statistics.
     * Matches Next.js dashboard calculations
     */
    public function stats(Request $request)
    {
        // Get date range (default to current month)
        $startDate = $request->input('start_date', now()->startOfMonth()->toDateString());
        $endDate = $request->input('end_date', now()->endOfMonth()->toDateString());

        // Get all transactions in date range
        $transactions = Transaction::dateRange($startDate, $endDate)->get();

        // Calculate totals (matching Next.js logic)
        $totalRevenue = $transactions->where('type', Transaction::TYPE_REVENUE)->sum('amount');
        $totalExpense = $transactions->where('type', Transaction::TYPE_TRANSACTION)->sum('amount');
        $balance = $totalRevenue - $totalExpense;

        // Sales by method (matching Next.js salesByMethod)
        $salesByMethod = [
            'cash' => $transactions->where('type', Transaction::TYPE_REVENUE)
                ->where('category', 'Cash')->sum('amount'),
            'gcash' => $transactions->where('type', Transaction::TYPE_REVENUE)
                ->where('category', 'GCash')->sum('amount'),
            'grab' => $transactions->where('type', Transaction::TYPE_REVENUE)
                ->where('category', 'Grab')->sum('amount'),
            'paymaya' => $transactions->where('type', Transaction::TYPE_REVENUE)
                ->where('category', 'PayMaya')->sum('amount'),
        ];

        // Expenses by category (matching Next.js expensesByCategory)
        $expensesByCategory = $transactions
            ->where('type', Transaction::TYPE_TRANSACTION)
            ->groupBy('category')
            ->map(function ($categoryTransactions) {
                return [
                    'category' => $categoryTransactions->first()->category,
                    'total' => $categoryTransactions->sum('amount'),
                    'count' => $categoryTransactions->count(),
                ];
            })
            ->values();

        // Tax calculations (matching Next.js TaxSummary)
        $vatRate = 0.12;
        $withholdingTax = 0.02;
        $grossSales = $totalRevenue;
        $vatTax = $grossSales * $vatRate;
        $withholdingTaxAmount = $grossSales * $withholdingTax;
        $totalTaxes = $vatTax + $withholdingTaxAmount;

        return response()->json([
            'period' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
            'totals' => [
                'revenue' => (float) $totalRevenue,
                'expense' => (float) $totalExpense,
                'balance' => (float) $balance,
            ],
            'sales_by_method' => [
                'cash' => (float) $salesByMethod['cash'],
                'gcash' => (float) $salesByMethod['gcash'],
                'grab' => (float) $salesByMethod['grab'],
                'paymaya' => (float) $salesByMethod['paymaya'],
                'total' => (float) array_sum($salesByMethod),
            ],
            'expenses_by_category' => $expensesByCategory,
            'taxes' => [
                'gross_sales' => (float) $grossSales,
                'vat_rate' => $vatRate,
                'vat_amount' => (float) $vatTax,
                'withholding_rate' => $withholdingTax,
                'withholding_amount' => (float) $withholdingTaxAmount,
                'total_taxes' => (float) $totalTaxes,
            ],
            'transaction_count' => $transactions->count(),
        ]);
    }

    /**
     * Get available categories based on type.
     * Matches Next.js categories
     */
    public function categories(Request $request)
    {
        $type = $request->input('type', 'revenue');

        $categories = $type === Transaction::TYPE_REVENUE
            ? Transaction::REVENUE_CATEGORIES
            : Transaction::TRANSACTION_CATEGORIES;

        return response()->json([
            'type' => $type,
            'categories' => $categories,
        ]);
    }

    /**
     * Get available payment methods.
     * Matches Next.js PAYMENT_METHODS
     */
    public function paymentMethods()
    {
        return response()->json([
            'payment_methods' => Transaction::PAYMENT_METHODS,
        ]);
    }
}
