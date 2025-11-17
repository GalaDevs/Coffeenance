<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Transaction;
use Carbon\Carbon;

class TransactionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     * Creates sample transactions matching Next.js data structure
     */
    public function run(): void
    {
        $today = Carbon::today();

        // Sample Revenue Transactions
        $revenueTransactions = [
            [
                'date' => $today->toDateString(),
                'type' => Transaction::TYPE_REVENUE,
                'category' => 'Cash',
                'description' => 'Morning sales',
                'amount' => 1500.00,
                'payment_method' => 'Cash',
                'transaction_number' => 'TXN' . now()->timestamp . '001',
                'receipt_number' => 'RCP' . now()->timestamp . '001',
                'vat' => 0,
            ],
            [
                'date' => $today->toDateString(),
                'type' => Transaction::TYPE_REVENUE,
                'category' => 'GCash',
                'description' => 'Afternoon online orders',
                'amount' => 850.00,
                'payment_method' => 'GCash',
                'transaction_number' => 'TXN' . now()->timestamp . '002',
                'receipt_number' => 'RCP' . now()->timestamp . '002',
                'vat' => 0,
            ],
            [
                'date' => $today->toDateString(),
                'type' => Transaction::TYPE_REVENUE,
                'category' => 'Grab',
                'description' => 'Delivery orders',
                'amount' => 620.00,
                'payment_method' => 'Grab',
                'transaction_number' => 'TXN' . now()->timestamp . '003',
                'receipt_number' => 'RCP' . now()->timestamp . '003',
                'vat' => 0,
            ],
            [
                'date' => $today->toDateString(),
                'type' => Transaction::TYPE_REVENUE,
                'category' => 'PayMaya',
                'description' => 'Evening sales',
                'amount' => 430.00,
                'payment_method' => 'PayMaya',
                'transaction_number' => 'TXN' . now()->timestamp . '004',
                'receipt_number' => 'RCP' . now()->timestamp . '004',
                'vat' => 0,
            ],
        ];

        // Sample Transaction (Expense) Transactions
        $expenseTransactions = [
            [
                'date' => $today->toDateString(),
                'type' => Transaction::TYPE_TRANSACTION,
                'category' => 'Supplies',
                'description' => 'Coffee beans purchase',
                'amount' => 850.00,
                'payment_method' => 'Bank Transfer',
                'transaction_number' => 'TXN' . now()->timestamp . '101',
                'receipt_number' => 'RCP' . now()->timestamp . '101',
                'tin_number' => '123-456-789',
                'vat' => 12,
                'supplier_name' => 'Premium Coffee Suppliers Inc.',
                'supplier_address' => 'Manila, Philippines',
            ],
            [
                'date' => $today->toDateString(),
                'type' => Transaction::TYPE_TRANSACTION,
                'category' => 'Pastries',
                'description' => 'Fresh pastries and breads',
                'amount' => 320.00,
                'payment_method' => 'Cash',
                'transaction_number' => 'TXN' . now()->timestamp . '102',
                'receipt_number' => 'RCP' . now()->timestamp . '102',
                'tin_number' => '987-654-321',
                'vat' => 12,
                'supplier_name' => 'Local Bakery Co.',
                'supplier_address' => 'Quezon City, Philippines',
            ],
            [
                'date' => $today->subDays(1)->toDateString(),
                'type' => Transaction::TYPE_TRANSACTION,
                'category' => 'Utilities',
                'description' => 'Monthly electricity bill',
                'amount' => 1200.00,
                'payment_method' => 'Check',
                'transaction_number' => 'TXN' . now()->timestamp . '103',
                'receipt_number' => 'RCP' . now()->timestamp . '103',
                'vat' => 0,
            ],
            [
                'date' => $today->subDays(2)->toDateString(),
                'type' => Transaction::TYPE_TRANSACTION,
                'category' => 'Manpower',
                'description' => 'Staff salaries - Week 1',
                'amount' => 5000.00,
                'payment_method' => 'Bank Transfer',
                'transaction_number' => 'TXN' . now()->timestamp . '104',
                'receipt_number' => 'RCP' . now()->timestamp . '104',
                'vat' => 0,
            ],
        ];

        // Insert all transactions
        foreach (array_merge($revenueTransactions, $expenseTransactions) as $transaction) {
            Transaction::create($transaction);
        }

        $this->command->info('Sample transactions seeded successfully!');
        $this->command->info('Revenue transactions: ' . count($revenueTransactions));
        $this->command->info('Expense transactions: ' . count($expenseTransactions));
    }
}
