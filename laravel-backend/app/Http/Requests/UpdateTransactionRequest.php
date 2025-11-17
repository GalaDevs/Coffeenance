<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use App\Models\Transaction;

/**
 * Update Transaction Request
 * Matches Next.js validation logic
 */
class UpdateTransactionRequest extends FormRequest
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
     */
    public function rules(): array
    {
        return [
            'type' => ['sometimes', 'in:' . Transaction::TYPE_REVENUE . ',' . Transaction::TYPE_TRANSACTION],
            'category' => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'string', 'max:1000'],
            'amount' => ['sometimes', 'numeric', 'min:0.01'],
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
            'amount.min' => 'Amount must be greater than 0',
            'type.in' => 'Transaction type must be revenue or transaction',
        ];
    }
}
