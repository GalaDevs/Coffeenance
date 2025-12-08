# Apply KPI Targets Cloud Migration

## Step 1: Run SQL Migration in Supabase Dashboard

1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy and paste the contents of `supabase/migrations/create_kpi_targets_table.sql`
5. Click **Run** to execute the migration

## Step 2: Verify Table Creation

Run this query to verify the table was created:

```sql
SELECT * FROM kpi_targets LIMIT 1;
```

You should see the table structure with columns:
- id
- shop_id
- user_id
- target_key
- target_value
- month
- year
- created_at
- updated_at

## Step 3: Test the App

After deploying the app, the KPI targets will automatically:
- ✅ Sync to cloud on save
- ✅ Load from cloud on app start
- ✅ Share across all devices
- ✅ Persist after uninstall/reinstall
- ✅ Support multi-shop (using admin_id as shop identifier)

## Step 4: Migration Notes

The app will automatically:
1. Create default targets in the cloud if none exist
2. Fall back to local storage if cloud is unavailable
3. Sync targets whenever you save them

## Security

Row Level Security (RLS) ensures:
- Users can only see their shop's targets
- Only admins and managers can create/update targets
- Only admins can delete targets
- Staff can view but not modify targets
