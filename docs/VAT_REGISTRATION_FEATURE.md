# VAT Registration Feature

## Overview
Added VAT registration field to shop settings during registration process.

## Changes Made

### 1. Database Migration
**File**: `supabase/migrations/20251214000001_add_vat_registration.sql`
- Added `is_vat_registered` boolean column to `shop_settings` table
- Default value: `false`
- Run this migration in Supabase SQL Editor

### 2. Model Updates
**File**: `lib/models/shop_settings.dart`
- Added `isVatRegistered` field to `ShopSettings` model
- Updated `fromJson()`, `toJson()`, and `copyWith()` methods

### 3. Service Updates
**File**: `lib/services/shop_settings_service.dart`
- Updated `upsertShopSettings()` to include `isVatRegistered` parameter
- Added `updateVatRegistration()` method for updating VAT status

### 4. Registration Dialog
**File**: `lib/widgets/register_dialog.dart`
- Added VAT registration switch in registration form
- Switch label: "VAT Registered"
- Subtitle: "Is your business VAT registered?"
- Saves VAT status during shop settings creation

## Usage

### During Registration:
1. User fills in coffee shop details
2. Toggle "VAT Registered" switch if business is VAT registered
3. VAT status is saved to shop_settings table

### VAT Display Logic:
- If `isVatRegistered == true`: Show VAT-related fields/calculations
- If `isVatRegistered == false`: Hide VAT-related fields/calculations

## Migration Instructions

Run in Supabase SQL Editor:
```sql
-- Add is_vat_registered column
ALTER TABLE public.shop_settings
ADD COLUMN IF NOT EXISTS is_vat_registered BOOLEAN DEFAULT false NOT NULL;
```

## Future Enhancements
- Add VAT settings toggle in Settings screen
- Add VAT calculations in transactions
- Add VAT reports/summaries
