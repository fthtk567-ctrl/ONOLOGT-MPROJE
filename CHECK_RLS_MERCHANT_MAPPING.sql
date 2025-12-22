-- onlog_merchant_mapping tablosunun RLS durumunu kontrol et
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'onlog_merchant_mapping';

-- RLS Policy'leri listele
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'onlog_merchant_mapping';

-- Eğer RLS aktifse, service_role için devre dışı bırak veya SELECT izni ver
ALTER TABLE onlog_merchant_mapping DISABLE ROW LEVEL SECURITY;
