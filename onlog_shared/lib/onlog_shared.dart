/// ONLOG Shared Package
/// 
/// Ortak modeller ve servisler
/// Merchant Panel, Courier App ve Admin Panel tarafından kullanılır
library;

// Supabase Configuration
export 'config/supabase_config.dart';

// Core Supabase Service
export 'services/supabase_service.dart';

// Models
export 'models/order.dart';
export 'models/courier.dart';
export 'models/merchant.dart';
export 'models/manual_delivery.dart';
export 'models/delivery_request.dart'; // ⭐ YENİ - Yemek App entegrasyonu
export 'models/financial.dart';
export 'models/legal_document.dart';
export 'models/legal_consent.dart';
export 'models/merchant_integration_status.dart';

// Supabase Services (NEW!)
export 'services/supabase_legal_service.dart';
export 'services/supabase_trendyol_service.dart';
export 'services/supabase_payment_service.dart';
export 'services/supabase_risk_service.dart';
export 'services/supabase_seeder_service.dart';
export 'services/supabase_order_service.dart';
export 'services/supabase_user_service.dart';
export 'services/supabase_delivery_service.dart';
export 'services/supabase_fcm_service.dart'; // Push Notifications
export 'services/supabase_merchant_integration_service.dart';

// Legacy Firebase Services
export 'services/legal_service.dart';

// Widgets
export 'widgets/legal_consent_widget.dart';

// Utils
export 'utils/legal_templates.dart';
