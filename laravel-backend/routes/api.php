<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\TransactionController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Transaction API routes
Route::prefix('transactions')->group(function () {
    // Standard CRUD
    Route::get('/', [TransactionController::class, 'index']); // GET /api/transactions
    Route::post('/', [TransactionController::class, 'store']); // POST /api/transactions
    Route::get('/{transaction}', [TransactionController::class, 'show']); // GET /api/transactions/{id}
    Route::put('/{transaction}', [TransactionController::class, 'update']); // PUT /api/transactions/{id}
    Route::delete('/{transaction}', [TransactionController::class, 'destroy']); // DELETE /api/transactions/{id}
    
    // Additional endpoints
    Route::get('/stats/dashboard', [TransactionController::class, 'stats']); // GET /api/transactions/stats/dashboard
    Route::get('/meta/categories', [TransactionController::class, 'categories']); // GET /api/transactions/meta/categories
    Route::get('/meta/payment-methods', [TransactionController::class, 'paymentMethods']); // GET /api/transactions/meta/payment-methods
});

// Health check
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toISOString(),
        'app' => config('app.name'),
    ]);
});
