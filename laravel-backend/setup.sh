#!/bin/bash

# Laravel Backend Setup Script
# Sets up the Laravel API for CoffeeFlow/Coffeenance

echo "🚀 CoffeeFlow Laravel Backend Setup"
echo "===================================="
echo ""

# Navigate to laravel-backend directory
cd "$(dirname "$0")"

echo "📍 Current directory: $(pwd)"
echo ""

# Check if composer is installed
if ! command -v composer &> /dev/null; then
    echo "❌ Composer is not installed!"
    echo "Please install Composer from https://getcomposer.org/"
    exit 1
fi

echo "✅ Composer found: $(composer --version | head -n 1)"
echo ""

# Check if Laravel is installed
if [ ! -f "composer.json" ]; then
    echo "📦 Installing Laravel..."
    composer create-project laravel/laravel . "^11.0"
    echo ""
fi

# Install dependencies
echo "📦 Installing dependencies..."
composer install
echo ""

# Copy .env.example if .env doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    php artisan key:generate
    echo ""
fi

# Configure database (SQLite for simplicity)
echo "🗄️  Configuring database..."
if [ ! -f "database/database.sqlite" ]; then
    touch database/database.sqlite
    echo "Created SQLite database"
fi

# Update .env for SQLite
if grep -q "DB_CONNECTION=mysql" .env; then
    sed -i.bak 's/DB_CONNECTION=mysql/DB_CONNECTION=sqlite/' .env
    sed -i.bak 's/# DB_DATABASE=/DB_DATABASE=/' .env
    echo "Updated .env for SQLite"
fi
echo ""

# Run migrations
echo "🔄 Running migrations..."
php artisan migrate:fresh
echo ""

# Run seeders
echo "🌱 Seeding database..."
php artisan db:seed --class=TransactionSeeder
echo ""

# Clear and cache config
echo "🧹 Clearing cache..."
php artisan config:clear
php artisan cache:clear
php artisan route:clear
echo ""

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Start the server: php artisan serve"
echo "  2. API will be available at: http://localhost:8000/api"
echo ""
echo "🔗 Available endpoints:"
echo "  - GET    /api/transactions             - List all transactions"
echo "  - POST   /api/transactions             - Create new transaction"
echo "  - GET    /api/transactions/{id}        - Get single transaction"
echo "  - PUT    /api/transactions/{id}        - Update transaction"
echo "  - DELETE /api/transactions/{id}        - Delete transaction"
echo "  - GET    /api/transactions/stats/dashboard  - Get dashboard stats"
echo "  - GET    /api/transactions/meta/categories  - Get categories"
echo "  - GET    /api/transactions/meta/payment-methods  - Get payment methods"
echo "  - GET    /api/health                   - Health check"
echo ""
