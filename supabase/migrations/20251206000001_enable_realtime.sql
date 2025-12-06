-- Enable Realtime for Coffeenance
-- Created: 2025-12-06

-- Enable realtime replication for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE inventory;
ALTER PUBLICATION supabase_realtime ADD TABLE staff;
ALTER PUBLICATION supabase_realtime ADD TABLE kpi_settings;
ALTER PUBLICATION supabase_realtime ADD TABLE tax_settings;
