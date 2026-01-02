-- Drop old policies
DROP POLICY IF EXISTS "Users can view own custom categories" ON custom_categories;
DROP POLICY IF EXISTS "Users can insert own custom categories" ON custom_categories;
DROP POLICY IF EXISTS "Users can delete own custom categories" ON custom_categories;
DROP POLICY IF EXISTS "Users can view admin circle custom categories" ON custom_categories;
DROP POLICY IF EXISTS "Users can insert admin circle custom categories" ON custom_categories;
DROP POLICY IF EXISTS "Users can delete admin circle custom categories" ON custom_categories;

-- Policy: Users can view custom categories from their admin circle
-- (admin, managers, and staff can all see the admin's custom categories)
CREATE POLICY "Users can view admin circle custom categories"
    ON custom_categories
    FOR SELECT
    USING (
        admin_id IN (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
    );

-- Policy: Users can insert custom categories under their admin
CREATE POLICY "Users can insert admin circle custom categories"
    ON custom_categories
    FOR INSERT
    WITH CHECK (
        admin_id IN (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
    );

-- Policy: Users can delete custom categories from their admin circle
CREATE POLICY "Users can delete admin circle custom categories"
    ON custom_categories
    FOR DELETE
    USING (
        admin_id IN (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
    );
