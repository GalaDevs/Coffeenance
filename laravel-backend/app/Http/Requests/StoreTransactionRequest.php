<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use App\Models\Transaction;

/**
 * Store Transaction Request
 * Matches Next.js validation logic
 */
class StoreTransactionRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     * Matches Next.js required fields: category, amount, description
     */
    public function rules(): array
    {
        return [
            'type' => ['required', 'in:' . Transaction::TYPE_REVENUE . ',' . Transaction::TYPE_TRANSACTION],
            'category' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:1000'],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'payment_method' => ['nullable', 'string', 'max:255'],
            'transaction_number' => ['nullable', 'string', 'max:255'],
            'receipt_number' => ['nullable', 'string', 'max:255'],
            'tin_number' => ['nullable', 'string', 'max:255'],
            'vat' => ['nullable', 'integer', 'in:0,12'],
            'supplier_name' => ['nullable', 'string', 'max:500'],
            'supplier_address' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * Get custom messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'category.required' => 'Please select a category',
            'description.required' => 'Please enter a description',
            'amount.required' => 'Please enter an amount',
            'amount.min' => 'Amount must be greater than 0',
            'type.in' => 'Transaction type must be revenue or transaction',
        ];
    }

    /**
     * Prepare the data for validation.
     * Matches Next.js logic for auto-generating values
     */
    protected function prepareForValidation(): void
    {
        // Auto-generate transaction number if not provided (matching Next.js TXN${Date.now()})
        if (empty($this->transaction_number)) {
            $this->merge([
                'transaction_number' => 'TXN' . now()->timestamp . rand(100, 999),
            ]);
        }

        // Auto-generate receipt number if not provided (matching Next.js RCP${Date.now()})
        if (empty($this->receipt_number)) {
            $this->merge([
                'receipt_number' => 'RCP' . now()->timestamp . rand(100, 999),
            ]);
        }

        // Default payment method to category if not provided (matching Next.js logic)
        if (empty($this->payment_method)) {
            $this->merge([
                'payment_method' => $this->category,
            ]);
        }

        // Default VAT to 0 if not provided
        if (!isset($this->vat)) {
            $this->merge([
                'vat' => 0,
            ]);
        }

        // Set date to today if not provided
        if (!isset($this->date)) {
            $this->merge([
                'date' => now()->toDateString(),
            ]);
        }
    }
}
