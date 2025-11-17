<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Matches Next.js and Flutter transaction structure
     */
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->date('date');
            $table->enum('type', ['revenue', 'transaction']); // revenue or transaction (expense)
            $table->string('category');
            $table->text('description');
            $table->decimal('amount', 12, 2); // up to 999,999,999.99
            $table->string('payment_method')->nullable();
            $table->string('transaction_number')->nullable();
            $table->string('receipt_number')->nullable();
            $table->string('tin_number')->nullable();
            $table->integer('vat')->default(0); // 0 or 12
            $table->string('supplier_name')->nullable();
            $table->text('supplier_address')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // Indexes for common queries
            $table->index('date');
            $table->index('type');
            $table->index('category');
            $table->index(['type', 'date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
