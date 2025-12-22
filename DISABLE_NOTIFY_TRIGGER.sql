-- notify_courier_via_edge_function trigger'ını DEVRE DIŞI BIRAK
-- Çünkü Flutter'dan zaten manuel HTTP POST yapıyoruz
ALTER TABLE delivery_requests DISABLE TRIGGER trigger_notify_courier_on_insert;
ALTER TABLE delivery_requests DISABLE TRIGGER trigger_notify_courier_on_assign;
