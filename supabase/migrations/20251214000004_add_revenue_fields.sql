-- Add sub_category and invoice_number columns to transactions table
ALTER TABLE transactions 
ADD COLUMN IF NOT EXISTS sub_category TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS invoice_number TEXT DEFAULT '';

-- Create index for invoice number searches
CREATE INDEX IF NOT EXISTS idx_transactions_invoice_number ON transactions(invoice_number);
