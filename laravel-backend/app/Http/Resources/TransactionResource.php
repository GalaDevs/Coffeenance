<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Transaction Resource
 * Formats transaction data matching Next.js structure
 */
class TransactionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     * Matches Next.js transaction object structure
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'date' => $this->date->format('Y-m-d'),
            'type' => $this->type,
            'category' => $this->category,
            'description' => $this->description,
            'amount' => (float) $this->amount,
            'paymentMethod' => $this->payment_method, // camelCase for JS
            'transactionNumber' => $this->transaction_number, // camelCase for JS
            'receiptNumber' => $this->receipt_number, // camelCase for JS
            'tinNumber' => $this->tin_number, // camelCase for JS
            'vat' => $this->vat,
            'supplierName' => $this->supplier_name, // camelCase for JS
            'supplierAddress' => $this->supplier_address, // camelCase for JS
            'vatAmount' => (float) $this->vat_amount, // Calculated field
            'amountWithVat' => (float) $this->amount_with_vat, // Calculated field
            'createdAt' => $this->created_at?->toISOString(),
            'updatedAt' => $this->updated_at?->toISOString(),
        ];
    }
}
