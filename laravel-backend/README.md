# CoffeeFlow Laravel Backend API

RESTful API backend for CoffeeFlow/Coffeenance transaction management system. Matches Next.js and Flutter implementations exactly.

## 🚀 Quick Start

```bash
cd laravel-backend
chmod +x setup.sh
./setup.sh
php artisan serve
```

API will be available at `http://localhost:8000/api`

## 📋 Features

- ✅ Complete transaction CRUD operations
- ✅ Revenue and expense categorization
- ✅ Dashboard statistics with calculations matching Next.js
- ✅ VAT and tax calculations
- ✅ Payment method tracking
- ✅ Supplier information management
- ✅ Date range filtering
- ✅ RESTful API design

## 🗄️ Database Schema

### Transactions Table

| Field | Type | Description |
|-------|------|-------------|
| `id` | bigint | Primary key |
| `date` | date | Transaction date |
| `type` | enum | `revenue` or `transaction` (expense) |
| `category` | string | Category name |
| `description` | text | Transaction description |
| `amount` | decimal(12,2) | Transaction amount |
| `payment_method` | string | Payment method used |
| `transaction_number` | string | Unique transaction number |
| `receipt_number` | string | Official receipt number |
| `tin_number` | string | Tax identification number |
| `vat` | integer | VAT percentage (0 or 12) |
| `supplier_name` | string | Supplier/vendor name |
| `supplier_address` | text | Supplier address |
| `created_at` | timestamp | Record creation time |
| `updated_at` | timestamp | Last update time |
| `deleted_at` | timestamp | Soft delete timestamp |

## 🔌 API Endpoints

### Transactions

#### List All Transactions
```http
GET /api/transactions
```

Query parameters:
- `type` - Filter by type (`revenue` or `transaction`)
- `category` - Filter by category
- `start_date` - Start date (YYYY-MM-DD)
- `end_date` - End date (YYYY-MM-DD)
- `per_page` - Items per page (pagination)

#### Create Transaction
```http
POST /api/transactions
Content-Type: application/json

{
  "type": "revenue",
  "category": "Cash",
  "description": "Morning sales",
  "amount": 1500.00,
  "payment_method": "Cash",
  "transaction_number": "TXN001",
  "receipt_number": "RCP001",
  "tin_number": "123-456-789",
  "vat": 0,
  "supplier_name": "Coffee Supplier Inc.",
  "supplier_address": "Manila, PH"
}
```

Required fields: `type`, `category`, `description`, `amount`

#### Get Single Transaction
```http
GET /api/transactions/{id}
```

#### Update Transaction
```http
PUT /api/transactions/{id}
Content-Type: application/json

{
  "amount": 1600.00,
  "description": "Morning sales - Updated"
}
```

#### Delete Transaction
```http
DELETE /api/transactions/{id}
```

### Statistics

#### Dashboard Stats
```http
GET /api/transactions/stats/dashboard
```

Query parameters:
- `start_date` - Start date (YYYY-MM-DD)
- `end_date` - End date (YYYY-MM-DD)

Response:
```json
{
  "period": {
    "start_date": "2025-11-01",
    "end_date": "2025-11-30"
  },
  "totals": {
    "revenue": 3400.00,
    "expense": 7370.00,
    "balance": -3970.00
  },
  "sales_by_method": {
    "cash": 1500.00,
    "gcash": 850.00,
    "grab": 620.00,
    "paymaya": 430.00,
    "total": 3400.00
  },
  "expenses_by_category": [
    {
      "category": "Supplies",
      "total": 850.00,
      "count": 1
    }
  ],
  "taxes": {
    "gross_sales": 3400.00,
    "vat_rate": 0.12,
    "vat_amount": 408.00,
    "withholding_rate": 0.02,
    "withholding_amount": 68.00,
    "total_taxes": 476.00
  },
  "transaction_count": 8
}
```

### Metadata

#### Get Categories
```http
GET /api/transactions/meta/categories?type=revenue
```

Response:
```json
{
  "type": "revenue",
  "categories": ["Cash", "GCash", "Grab", "PayMaya", "Others"]
}
```

#### Get Payment Methods
```http
GET /api/transactions/meta/payment-methods
```

Response:
```json
{
  "payment_methods": [
    "Cash", "Check", "Bank Transfer", 
    "Credit Card", "GCash", "PayMaya", "Others"
  ]
}
```

### Health Check
```http
GET /api/health
```

## 📊 Business Logic

### Categories

**Revenue Categories:**
- Cash
- GCash
- Grab
- PayMaya
- Others

**Transaction (Expense) Categories:**
- Supplies
- Pastries
- Rent
- Utilities
- Manpower
- Marketing
- Others

### Payment Methods
- Cash
- Check
- Bank Transfer
- Credit Card
- GCash
- PayMaya
- Others

### VAT Calculation
- 0% (No VAT)
- 12% VAT

**Formula:**
```
VAT Amount = Amount × (VAT / 100)
Amount with VAT = Amount + VAT Amount
```

### Tax Summary (Matches Next.js)
```
VAT Rate = 12%
Withholding Tax = 2%

VAT Amount = Gross Sales × 0.12
Withholding Tax Amount = Gross Sales × 0.02
Total Taxes = VAT Amount + Withholding Tax Amount
```

### Dashboard Calculations
```
Total Revenue = Sum of all revenue transactions
Total Expense = Sum of all transaction (expense) transactions
Balance = Total Revenue - Total Expense
```

## 🔧 Development

### Requirements
- PHP 8.2+
- Composer
- SQLite (or MySQL/PostgreSQL)

### Installation

1. Install dependencies:
```bash
composer install
```

2. Setup environment:
```bash
cp .env.example .env
php artisan key:generate
```

3. Configure database in `.env`:
```env
DB_CONNECTION=sqlite
DB_DATABASE=/absolute/path/to/database.sqlite
```

4. Run migrations:
```bash
php artisan migrate
```

5. Seed sample data:
```bash
php artisan db:seed --class=TransactionSeeder
```

6. Start server:
```bash
php artisan serve
```

### Testing with cURL

Create a transaction:
```bash
curl -X POST http://localhost:8000/api/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "type": "revenue",
    "category": "Cash",
    "description": "Test sale",
    "amount": 100.00
  }'
```

Get dashboard stats:
```bash
curl http://localhost:8000/api/transactions/stats/dashboard
```

## 📱 Integration

### Flutter Integration

```dart
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:8000/api',
  headers: {'Accept': 'application/json'},
));

// Create transaction
final response = await dio.post('/transactions', data: {
  'type': 'revenue',
  'category': 'Cash',
  'description': 'Morning sales',
  'amount': 1500.00,
});
```

### Next.js Integration

```typescript
const response = await fetch('http://localhost:8000/api/transactions', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    type: 'revenue',
    category: 'Cash',
    description: 'Morning sales',
    amount: 1500.00,
  }),
});
```

## 📄 License

MIT License - See LICENSE file for details
