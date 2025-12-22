-- Test kuryelerini merchant'a çevir
UPDATE users
SET 
    role = 'merchant',
    business_name = 'Test İşletme ' || SUBSTRING(email FROM 5 FOR 1),  -- test5 -> Test İşletme 5
    owner_name = 'Test Sahip ' || SUBSTRING(email FROM 5 FOR 1),
    commission_settings = jsonb_build_object(
        'type', 'percentage',
        'business_type', 'restaurant',
        'commission_rate', 15.0,
        'minimum_order', 50.0
    ),
    payment_settings = jsonb_build_object(
        'payment_cycle', 'weekly',
        'payment_day', 1,
        'bank_info', jsonb_build_object(
            'bank_name', 'Test Banka',
            'iban', 'TR000000000000000000000000',
            'account_holder', 'Test Sahip'
        )
    ),
    updated_at = NOW()
WHERE email IN ('test5@deneme.com', 'test6@deneme.com')
RETURNING id, email, role, business_name, status;

-- Kontrol et
SELECT 
    id,
    email,
    role,
    business_name,
    owner_name,
    status,
    commission_settings,
    payment_settings
FROM users
WHERE email IN ('test5@deneme.com', 'test6@deneme.com');
