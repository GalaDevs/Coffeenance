<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Transaction Model
 * Matches Next.js and Flutter transaction structure
 */
class Transaction extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'date',
        'type',
        'category',
        'description',
        'amount',
        'payment_method',
        'transaction_number',
        'receipt_number',
        'tin_number',
        'vat',
        'supplier_name',
        'supplier_address',
    ];

    protected $casts = [
        'date' => 'date',
        'amount' => 'decimal:2',
        'vat' => 'integer',
    ];

    // Transaction types
    const TYPE_REVENUE = 'revenue';
    const TYPE_TRANSACTION = 'transaction';

    // Revenue categories (matching Next.js REVENUE_CATEGORIES)
    const REVENUE_CATEGORIES = [
        'Cash',
        'GCash',
        'Grab',
        'PayMaya',
        'Others',
    ];

    // Transaction categories (matching Next.js TRANSACTION_CATEGORIES)
    const TRANSACTION_CATEGORIES = [
        'Supplies',
        'Pastries',
        'Rent',
        'Utilities',
        'Manpower',
        'Marketing',
        'Others',
    ];

    // Payment methods (matching Next.js PAYMENT_METHODS)
    const PAYMENT_METHODS = [
        'Cash',
        'Check',
        'Bank Transfer',
        'Credit Card',
        'GCash',
        'PayMaya',
        'Others',
    ];

    /**
     * Scope for revenue transactions
     */
    public function scopeRevenue($query)
    {
        return $query->where('type', self::TYPE_REVENUE);
    }

    /**
     * Scope for transaction (expense) transactions
     */
    public function scopeTransactionType($query)
    {
        return $query->where('type', self::TYPE_TRANSACTION);
    }

    /**
     * Scope for date range
     */
    public function scopeDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('date', [$startDate, $endDate]);
    }

    /**
     * Scope for specific category
     */
    public function scopeCategory($query, $category)
    {
        return $query->where('category', $category);
    }

    /**
     * Calculate VAT amount
     */
    public function getVatAmountAttribute()
    {
        return $this->amount * ($this->vat / 100);
    }

    /**
     * Get amount including VAT
     */
    public function getAmountWithVatAttribute()
    {
        return $this->amount + $this->vat_amount;
    }
}
