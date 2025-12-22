-- notify_courier_via_edge_function fonksiyonunun FULL kodunu gör
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'notify_courier_via_edge_function';
