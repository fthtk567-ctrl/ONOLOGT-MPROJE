# ONLOG - AI Coding Agent Instructions

## System Overview
ONLOG is a **three-app Flutter courier/order management platform** for local merchants in Turkey. All apps share a **Supabase backend** with an automated financial payment system powered by PostgreSQL triggers.

### Project Structure
```
ONOLOGT-MPROJE/
├── onlog_shared/           # Shared package: models, services, Supabase client
├── onlog_merchant_panel/   # Merchant app (multi-platform: Android, iOS, Web, Desktop)
├── onlog_courier_app/      # Courier app (Android, iOS)
│   └── onlog_courier/      # Actual Flutter project (nested directory)
├── onlog_admin_panel/      # Admin app (Web only - system-wide management)
├── supabase/functions/     # Edge Functions for webhooks and FCM (Deno TypeScript)
│   ├── yemek-app-order-webhook/      # External order webhook integration
│   ├── send-courier-notification/     # Push notifications for couriers
│   ├── send-fcm-notification/         # Generic FCM sender
│   └── send-push-notification/        # Generic push notification delivery
└── *.sql, *_RAPORU.md      # 200+ SQL scripts & Turkish documentation
```

**Critical:** All apps depend on `onlog_shared` as a local path dependency (`path: ../onlog_shared`). Any changes to `onlog_shared` require running `flutter pub get` in all dependent apps.

**Documentation Language:** Most docs are in Turkish (`.md` files with `_RAPORU`, `_NASIL`, `_TAMAMLANDI` suffixes). Use these for context.

## Architecture & Data Flow

### Backend: Supabase (NOT Firebase)
- **Primary Database:** PostgreSQL on Supabase
- **Auth:** Supabase Auth with email/password
- **Realtime:** Enabled for `orders`, `payment_transactions`, `merchant_wallets`, `courier_wallets`
- **Storage:** Supabase Storage for delivery photos
- **Push Notifications:** Migrating from Firebase FCM to OneSignal
- **Key Tables:** `users`, `orders`, `payment_transactions`, `merchant_wallets`, `courier_wallets`, `commission_configs`, `fcm_tokens` (will become `push_tokens`)

### Automatic Payment System (CRITICAL)
When an order's `status` changes to `'DELIVERED'`:
1. PostgreSQL trigger `trigger_process_payment_on_delivery` fires automatically
2. Executes `process_order_payment_on_delivery()` function
3. Calculates commission (15% + 2 TL fixed fee + 18% VAT)
4. Creates `payment_transactions` records for merchant & courier
5. Updates `merchant_wallets` and `courier_wallets` balances

**Never implement manual payment logic** - the database trigger handles everything. See `SUPABASE_PAYMENT_SETUP.sql` for full setup.

### Shared Package (`onlog_shared`)
All Supabase logic lives here:
- **Entry point:** `lib/onlog_shared.dart` (exports all models/services)
- **Initialization:** Apps must call `await SupabaseService.initialize()` in `main()` before `runApp()`
- **Config:** `lib/config/supabase_config.dart` contains credentials and table names
- **Services:** `supabase_*.dart` services wrap all database operations (orders, users, payments, FCM, delivery, etc.)
- **Models:** `Order`, `Courier`, `Merchant`, `FinancialTransaction`, `ManualDelivery`, `DeliveryRequest`, etc.

Example initialization (see `onlog_merchant_panel/lib/main.dart`):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MyApp());
}
```

**Critical pattern:** Every app's `main.dart` must initialize Supabase before any UI. Check existing `main.dart` files for exact initialization order with Firebase/FCM.

**App Directory Quirk:** The courier app has a nested structure: `onlog_courier_app/onlog_courier/`. Always `cd` to the nested directory before Flutter commands.

## Critical Initialization Sequence

All apps follow this exact initialization pattern in `main.dart`:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. Immediately run `runApp()` with loading screen (for faster startup)
3. Initialize services asynchronously in background:
   - `SupabaseService.initialize()` (always first!)
   - `Firebase.initializeApp()` (if using FCM)
   - `initializeDateFormatting('tr_TR')` (Turkish locale)
   - App-specific services (Trendyol, FCM, etc.)
4. Set `_isAppInitialized = true` flag when done

**Example from merchant panel:**
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: OnLogMerchantApp())); // Shows loading immediately
}

class _AppState extends State {
  @override
  void initState() {
    _initializeApp(); // Async initialization in background
  }
  
  Future<void> _initializeApp() async {
    await SupabaseService.initialize(); // ALWAYS FIRST
    await Firebase.initializeApp();
    await initializeDateFormatting('tr_TR');
    setState(() => _isAppInitialized = true);
  }
}
```

This pattern prevents black/white startup screens and provides immediate visual feedback.

## Development Workflows

### Running Apps
Each app is a separate Flutter project with its own `pubspec.yaml`:

**Merchant Panel (multi-platform):**
```bash
cd onlog_merchant_panel
flutter pub get
flutter run -d chrome        # Web
flutter run                   # Connected device
```

**Courier App (mobile):**
```bash
cd onlog_courier_app/onlog_courier  # Note: nested directory!
flutter pub get
flutter run                   # Android/iOS device
```

**Admin Panel (web-only):**
```bash
cd onlog_admin_panel
flutter pub get
flutter run -d chrome
```

### Adding Dependencies
1. Update the relevant app's `pubspec.yaml` (merchant/courier/admin)
2. If dependency is needed across apps, add to `onlog_shared/pubspec.yaml`
3. Run `flutter pub get` in the app directory
4. If modifying `onlog_shared`, run `flutter pub get` in ALL dependent apps

### Database Changes
1. Write SQL in a new `.sql` file at project root (see `SQL_*.sql`, `ADD_*.sql`, `CHECK_*.sql` examples)
2. Run SQL in Supabase Dashboard > SQL Editor (https://supabase.com/dashboard)
3. If adding tables, update `SupabaseConfig` constants in `onlog_shared/lib/config/supabase_config.dart`
4. Create/update service methods in `onlog_shared/lib/services/supabase_*.dart`
5. Export new services/models in `onlog_shared/lib/onlog_shared.dart`

**SQL naming convention:** Project root contains 200+ SQL files with patterns:
- `ADD_*.sql` - Schema additions (columns, tables)
- `CHECK_*.sql` - Verification queries (run these to debug/inspect database state)
- `SQL_*.sql` - General setup/migration scripts
- `FIX_*.sql` - Bug fixes and corrections
- `DEBUG_*.sql` - Debugging queries
- `CREATE_*.sql` - New table/function creation
- Descriptive names like `AUTO_CLEANUP_NOTIFICATIONS.sql`, `APPROVE_MERCHANT_MANUAL.sql`

**IMPORTANT:** Never execute `CHECK_*.sql` or `DEBUG_*.sql` files as migrations - they're read-only diagnostic tools.

**SQL Diagnostic Workflow:**
When troubleshooting database issues, use the extensive `CHECK_*.sql` library:
- Location issues: `CHECK_COURIER_LOCATION_LIVE.sql`, `CHECK_MERCHANT_LOCATIONS.sql`
- Order tracking: `CHECK_LATEST_ORDER.sql`, `CHECK_ORDER_STATUS.sql`
- Courier status: `CHECK_COURIER_STATUS_DETAILED.sql`, `CHECK_COURIER_AVAILABILITY.sql`
- Payment debugging: `DEBUG_WALLET_DATA.sql`, `CHECK_PAYMENT_TRANSACTIONS_STRUCTURE.sql`
- Trigger verification: `CHECK_ALL_TRIGGERS.sql`, `CHECK_TRIGGER_STATUS.sql`
- Webhook debugging: `CHECK_WEBHOOK_LOGS_DETAILED.sql`, `CHECK_DELIVERED_WEBHOOK_LOGS.sql`
- FCM/Notifications: `CHECK_FCM_TOKEN.sql`, `CHECK_NOTIFICATIONS_NOW.sql`

These files are production-tested diagnostic queries that safely inspect system state without modifications.

### Realtime Subscriptions
Example pattern from codebase:
```dart
// Enable realtime in Supabase Dashboard first!
final subscription = SupabaseService.client
  .from('orders')
  .stream(primaryKey: ['id'])
  .eq('status', 'pending')
  .listen((data) {
    // Handle updates
  });
```

## Key Conventions

### User Roles & Auth
- **Roles:** `'merchant'`, `'courier'`, `'admin'` stored in `users.role` column
- **Login Flow:** All apps use Supabase Auth email/password
- **RLS Policies:** Enforce role-based access at database level (see `FIX_RLS_POLICIES.sql`)

### Order Status Flow
```
'WAITING_COURIER' → 'ASSIGNED' → 'ACCEPTED' → 'PICKED_UP' → 'DELIVERED'
```
Only update to `'DELIVERED'` when courier confirms delivery with photo + amount collected.

### Financial Transactions
- **Type field values:** `'orderPayment'` (merchant), `'deliveryFee'` (courier), `'withdrawal'`, `'commission'`
- **Status values:** `'pending'`, `'completed'`, `'failed'`
- **Amount sign convention:** Positive for credits, negative for debits

### Location Tracking
- Courier app updates `users.current_location` (PostGIS point) every 30 seconds
- Use `ST_Distance` SQL function for proximity calculations
- See `SQL_UPDATE_COURIER_LOCATIONS.sql` for location data structure

### Platform Integration
- Trendyol/Yemek App API credentials stored in database tables
- External orders imported via webhooks (see `supabase/functions/yemek-app-order-webhook/`)
- Merchant mapping in `onlog_merchant_mapping` table (maps external IDs to internal merchant UUIDs)
- Configuration in `onlog_merchant_panel/lib/config/trendyol_config.dart`

## Common Tasks

### Adding a New Screen
1. Create screen file: `lib/screens/new_screen.dart`
2. Import in navigation file (e.g., `main_navigation_screen.dart`)
3. Add route/button in navigation widget

### Creating a New Database Table
1. Write `CREATE TABLE` SQL with RLS policies
2. Add constant to `SupabaseConfig.TABLE_*`
3. Create model class in `onlog_shared/lib/models/`
4. Export model in `onlog_shared/lib/onlog_shared.dart`
5. Create service in `onlog_shared/lib/services/supabase_*_service.dart`

### Testing Financial Flows
1. Create test order with status `'WAITING_COURIER'`
2. Assign courier (status → `'ASSIGNED'`)
3. Courier accepts (status → `'ACCEPTED'`)
4. Courier picks up (status → `'PICKED_UP'`)
5. Courier delivers (status → `'DELIVERED'`) ← Trigger fires here
6. Check `payment_transactions` and `*_wallets` tables for auto-generated records

### Debugging Payment Issues
- Check Supabase logs: Dashboard > Logs > Database
- Verify trigger exists: `SELECT * FROM information_schema.triggers WHERE trigger_name = 'trigger_process_payment_on_delivery';`
- Test commission config: `SELECT * FROM commission_configs WHERE merchant_id IS NULL;`
- See `OTOMATIK_ODEME_SISTEMI.md` for detailed troubleshooting

### Edge Functions & Webhooks
**Location:** `supabase/functions/` (TypeScript Deno functions)

Key functions:
- `send-courier-notification`, `send-fcm-notification` - FCM push notifications (will migrate to OneSignal)
- `send-push-notification` - Generic notification delivery (will be updated for OneSignal REST API)CM push notifications
- `send-push-notification` - Generic notification delivery

**Deployment pattern:**
```bash
supabase functions deploy <function-name> --project-ref oilldfyywtzybrmpyixx
```

**Environment variables:** Set in Supabase Dashboard > Settings > Edge Functions > Secrets:
- `YEMEK_APP_API_KEY` - External API authentication (Bearer token format: `sk_live_...`)
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` - Included by default

**Critical webhook patterns:**
- Always use `createClient(url, SERVICE_ROLE_KEY)` for admin operations
- Normalize string comparisons: `trim().toLowerCase()` for matching IDs
- Use manual JS filtering if PostgreSQL text comparison fails (see yemek-app-order-webhook)
- Return proper CORS headers for all responses including errors
- Log extensively with `console.log('[Function Name]', context)` for debugging

**Testing webhooks locally:**
```bash
curl -X POST "https://oilldfyywtzybrmpyixx.supabase.co/functions/v1/yemek-app-order-webhook" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"restaurant_id":"R-TEST-001","order_id":"TEST-123",...}'
```

## Important Files

- **Setup Guide:** `KURULUM_KONTROL_LISTESI.md` - Complete system setup checklist (512 lines)
- **Payment System:** `SISTEM_AKIS_SEMASI.md` - Full payment flow diagram with mermaid charts
- **Quick Start:** `HIZLI_BASLANGIC.md` - Daily startup procedures (388 lines)
- **Database Schema:** `supabase_schema.sql` - Complete table definitions
- **Payment SQL:** `SUPABASE_PAYMENT_SETUP.sql` - Payment trigger & functions
- **Admin Setup:** `ADMIN_PANEL_NASIL_CALISTIRILIR.md` - Admin panel configuration
- **Yemek App Integration:** `YEMEK_APP_ENTEGRASYON_TAMAMLANDI.md` - External webhook integration docs (298 lines)
- **Build/Deploy:** `COURIER_GOOGLE_PLAY_HAZIRLIK.md` - Release build instructions
- **Troubleshooting:** Check `DEBUG_*.sql` and `CHECK_*.sql` files for diagnostic queries

## Project-Specific Patterns

### State Management
- **Merchant/Admin Panel:** Riverpod (`flutter_riverpod`) + Provider for theme
- **Courier App:** Hive (local storage) + Supabase realtime streams
- Avoid mixing - each app has its own pattern

### Theming
Apps support dark mode. Check for:
- `Theme.of(context).colorScheme.primary` not hardcoded colors
- `ThemeProvider` in merchant/admin panels

### Excel Export
Merchant & Admin panels can export reports:
```dart
import 'package:excel/excel.dart';
// Generate Excel file, save with path_provider, open with open_file
```
See `reports_page.dart` for examples.

### Audio Notifications
Merchant panel plays sounds on new orders:
```dart
import 'package:audioplayers/audioplayers.dart';
// assets/sounds/ directory
```

### Maps
- **Merchant/Admin:** `flutter_map` with OpenStreetMap (free)
- **Courier:** `google_maps_flutter` (requires API key in Android manifest)

## Known Issues & Workarounds

1. **"Supabase not initialized" error:** Ensure `SupabaseService.initialize()` called before any Supabase access
2. **Realtime not working:** Enable realtime for table in Supabase Dashboard > Database > Replication
3. **RLS Policy errors:** Check user's `role` field matches policy conditions
4. **Courier location not updating:** Verify location permissions granted and `current_location` column type is `geography(Point,4326)`

## SQL Pattern Conventions

When writing Supabase SQL:
- Always include RLS policies: `ALTER TABLE x ENABLE ROW LEVEL SECURITY;`
- Use `auth.uid()` for user-specific policies
- Add indexes for foreign keys and frequently queried columns
- Use triggers sparingly - only for automated calculations
- Timestamp columns: `created_at` (default `now()`), `updated_at` (via trigger)

## Never Do This

- ❌ Don't manually calculate commissions in Flutter - use the database trigger
- ❌ Don't use Firebase SDK for database - this project uses Supabase (Firebase only for FCM, migrating to OneSignal)
- ❌ Don't modify `onlog_shared` without running `flutter pub get` in all apps
- ❌ Don't hardcode user IDs or credentials - use Supabase Auth
- ❌ Don't create separate copies of models - use `onlog_shared` exports
- ❌ Don't add new FCM dependencies - we're migrating to OneSignal

## When You're Stuck

1. Check the relevant `*_RAPORU.md` files - they document completed features
2. Review `SISTEM_AKIS_SEMASI.md` for system-wide data flows
3. Inspect similar screens in the same app for UI patterns
4. For payment issues, see `OTOMATIK_ODEME_SISTEMI.md`
5. For Supabase queries, check `onlog_shared/lib/services/` implementations

---

## 🚴 Courier App Development Guide

### App Structure (Nested Directory)
```
onlog_courier_app/
└── onlog_courier/          # ← Actual Flutter project (IMPORTANT!)
    ├── lib/
    │   ├── courier/         # Main courier features
    │   │   ├── screens/     # UI screens
    │   │   └── widgets/     # Reusable components
    │   ├── cargo/           # Cargo/package delivery features
    │   ├── screens/         # Shared screens (auth, etc.)
    │   ├── services/        # Local services
    │   ├── shared/          # Shared utilities
    │   └── main.dart        # Entry point
    ├── android/             # Android-specific config
    ├── ios/                 # iOS-specific config
    └── pubspec.yaml         # Dependencies
```

**Critical:** Always `cd onlog_courier_app/onlog_courier` before running Flutter commands!

### Key Screens
- `CourierHomeScreen` - Main delivery list and status
- `CourierNavigationScreen` - Bottom tab navigation (4 tabs)
- `MapScreen` - Google Maps integration for navigation
- `DeliveryDetailsScreen` - Order details and actions (accept/reject/deliver)
- `EarningsScreen` - Payment history and statistics
- `CourierProfileScreen` - Profile and settings
- `NotificationsScreen` - Push notification history

### Dependencies (pubspec.yaml)
```yaml
dependencies:
  # Core (no onlog_shared - uses own implementation)
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.9
  
  # Storage & Preferences
  shared_preferences: ^2.2.2  # Local data persistence
  
  # Media & Files
  image_picker: ^1.2.0        # Delivery photo capture
  file_picker: ^10.3.3        # Document uploads
  
  # System
  url_launcher: ^6.3.2        # External links (phone, maps)
  permission_handler: ^12.0.1  # Location/camera permissions
```

**Note:** Courier app does NOT use `onlog_shared` package. It has its own Supabase/Firebase integration in `lib/services/`.

### Development Workflow

**1. Navigate to nested directory:**
```bash
cd onlog_courier_app/onlog_courier
```

**2. Running the app:**
```bash
flutter pub get
flutter run  # For connected Android/iOS device
```

**3. Building release APK (Android):**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**4. Common issues:**
- **Error:** "No pubspec.yaml found" → You're in wrong directory (go to `onlog_courier/`)
- **Google Maps not showing:** Check API key in `android/app/src/main/AndroidManifest.xml`
- **Location not updating:** Verify permissions in `AndroidManifest.xml` and runtime permission handling

### State Management Pattern
Courier app uses **StatefulWidget + setState** (no Riverpod/Provider):
```dart
class _CourierHomeScreenState extends State<CourierHomeScreen> {
  List<Order> _orders = [];
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  Future<void> _loadOrders() async {
    // Direct Supabase calls from services
    final orders = await OrderService.getActiveOrders();
    setState(() => _orders = orders);
  }
}
```

### Location Tracking
Courier app updates location every 30 seconds when active:
```dart
// In lib/services/location_service.dart
Timer.periodic(Duration(seconds: 30), (timer) {
  _updateCourierLocation();
});
```

Location is sent to `users.current_location` (PostGIS point) in Supabase.

### Google Maps Integration
```dart
// android/app/src/main/AndroidManifest.xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

Get API key from: https://console.cloud.google.com/google/maps-apis/

### Push Notifications (MIGRATING: Firebase → OneSignal)
**Current State:** Firebase Cloud Messaging (FCM)
**Target State:** OneSignal (planned migration)

**Firebase Implementation (Current):**
- Token stored in `fcm_tokens` table with `user_id` and `platform`
- Edge function `send-courier-notification` sends notifications via FCM
- Courier app listens for:
  - New order assigned
  - Order cancelled
  - Payment received

**OneSignal Migration Plan:**
- Replace FCM SDK with OneSignal SDK in all apps
- Update `fcm_tokens` table → `push_tokens` (or rename columns)
- Modify Edge Functions to use OneSignal REST API
- Benefits: Better analytics, easier setup, multi-platform support
- See `FCM_V1_MIGRATION_SUMMARY.md` for current FCM setup

**Notification Flow (Will use OneSignal):**
```
SCENARIO 1: Yemek App Webhook (Ana Kullanım)
Yemek App Restaurant Panel → Webhook → ONLOG
    ↓
Order created (onlog_merchant_mapping ile merchant bulunur)
    ↓
Courier assigned → Edge Function
    ↓
OneSignal notification → COURIER ONLY
(Merchant'a bildirim GİTMEZ - Yemek App kendi gönderir)

SCENARIO 2: Direct Merchant Panel
Merchant Panel → ONLOG → Order created
    ↓
Courier assigned → Edge Function
    ↓
OneSignal notification → COURIER + MERCHANT
(Merchant'a onay bildirimi gider)

SCENARIO 3: Admin Actions
Admin Panel → Kurye başvurusu onay/red
    ↓
Edge Function → Resend API → Email sent
(OneSignal Email KULLANILMAZ - Resend kullanılır)
```

**Critical:** 
- Yemek App webhook entegrasyonu var (`yemek-app-order-webhook` edge function). Bu siparişlerde merchant'a bildirim GÖNDERME çünkü Yemek App kendi restaurant panelinde zaten gösteriyor.
- Email notifications için **Resend** kullanılacak, OneSignal Email özelliği kullanılmayacak.

**OneSignal Migration Steps:**

1. **Setup OneSignal Account & Apps:**
   
   **IMPORTANT:** Her Flutter uygulaması için AYRI OneSignal App oluştur! (3 app toplam)
   
   **Step 1.1: Create Courier App**
   - App Name: `ONLOG - Kurye Teslimat Uygulaması` 
   - Organization: Create new → `ONLOG` (veya mevcut varsa seç)
   - Platform: **iOS + Android + Web** seç (Email ATLA - Resend kullanacağız)
     - Mobil uygulama → iOS/Android push
     - Web dashboard → Web push
     - Email bildirimleri → **Resend** ile ayrı yapılacak
   - Click "Next: Configure Your Platform"
   
   **Step 1.2: Platform Configuration**
   - **Android (FCM):** 
     - Firebase Project ID: `onlog-push`
     - Package Name: `com.onlog.onlog_courier_app`
     - Upload `google-services.json` from Firebase Console
     - Save & Continue
   - **iOS (APNs):** 
     - Key Name: `ONLOG APNs Key`
     - Key ID: `742SDJ67S2`
     - Team ID: (Apple Developer Membership'ten alınacak)
     - Bundle ID: `com.onlog.onlog_courier_app`
     - Upload `AuthKey_742SDJ67S2.p8` file
     - Save & Continue
   - **Web Push:** Configure later → Save
   - Click "Save & Continue"
   
   **Step 1.3: Get Credentials**
   - Settings → Keys & IDs sayfasında:
   - **OneSignal App ID (Courier):** `8e0048f9-329e-49e3-ac4a-acb8e10a34ab`
   - **REST API Key (Courier):** `os_v2_app_ryaer6jstze6hlckvs4occruvor3crlct7fep4ftmze22xfwr3wcspk6grsvhocszguhclom62c3kbjvlpca5ft36d35cnfvhnmiwdy`
   
   **iOS Bundle ID (Courier):** `com.onlog.onlogCourierApp`
   **Android Package (Courier):** `com.onlog.onlog_courier_app`
   
   **Step 1.4: Repeat for Merchant App (OPTIONAL)**
   - Dashboard'a dön → "New App/Project" tıkla
   - App Name: `ONLOG - Satıcı Paneli`
   - Organization: `ONLOG` seç (aynı org altında)
   - Platform: iOS + Android + Web + Email seç
   - **NOT:** Yemek App webhook'tanseç (Email ATLA)
   - **NOT:** Yemek App webhook'tan gelen siparişlerde merchant'a bildirim gitmeyecek
   - Sadece direkt merchant panel'den oluşturulan siparişler için kullanılır
   - Aynı konfigürasyonu yap, yeni App ID + REST API Key kaydet
   
   **Step 1.5: Repeat for Admin App**
   - Dashboard'a dön → "New App/Project" tıkla
   - App Name: `ONLOG - Admin Yönetim Paneli`
   - Organization: `ONLOG` seç
   - Platform: Web seç (sadece web panel, mobil yok, Email ATLA)
   - Aynı konfigürasyonu yap, yeni App ID + REST API Key kaydet
   
   **SONUÇ:** 3 farklı OneSignal App, 3 farklı App ID, 3 farklı REST API Key
   
   **Email Notifications:** Resend kullanılacak (OneSignal Email kullanılmayacak)
   - Kurye başvuru onayı/red → Resend
   - Haftalık kazanç raporu → Resend
   - Sistem duyuruları → Resend
2. **Update Flutter Apps (Courier + Merchant + Admin):**
   ```yaml
   # pubspec.yaml
   dependencies:
     onesignal_flutter: ^5.0.0  # Remove firebase_messaging
   ```
   
   ```dart
   // main.dart initialization
   await OneSignal.shared.setAppId("YOUR_ONESIGNAL_APP_ID");
   
   // Get Player ID (replaces FCM token)
   final playerId = await OneSignal.shared.getDeviceState()
     .then((state) => state?.userId);
   
   // Save to database
   await supabase.from('push_tokens').upsert({
     'user_id': currentUserId,
     'player_id': playerId,
     'platform': Platform.isAndroid ? 'android' : 'ios',
   });
   ```

3. **Update Database Schema:**
   ```sql
   -- Rename fcm_tokens → push_tokens
   ALTER TABLE fcm_tokens RENAME TO push_tokens;
   
   -- Add OneSignal player_id column
   ALTER TABLE push_tokens 
   ADD COLUMN player_id TEXT,
   ADD COLUMN external_id TEXT;
   
   -- Keep old fcm_token for transition period
   -- DROP COLUMN fcm_token AFTER migration complete
   ```

4. **Update Edge Functions:**
   ```typescript
   // supabase/functions/send-push-notification/index.ts
   const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID');
   // Check order source
   const isFromYemekApp = order.metadata?.source === 'yemek_app';
   
   // Send to courier (ALWAYS)
   const response = await fetch('https://onesignal.com/api/v1/notifications', {
     method: 'POST',
     headers: {
       'Content-Type': 'application/json',
       'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
     },
     body: JSON.stringify({
       app_id: ONESIGNAL_APP_ID,
       include_player_ids: [courierPlayerId],
       headings: { tr: "Yeni Teslimat!" },
       contents: { tr: `Sipariş #${order.order_number} seni bekliyor` },
       data: { orderId: order.id, type: "new_delivery" },
     }),
   });
   
   // Send to merchant ONLY if NOT from Yemek App
   if (!isFromYemekApp) {
     await fetch('https://onesignal.com/api/v1/notifications', {
       method: 'POST',
       headers: {
         'Content-Type': 'application/json',
         'Authorization': `Basic ${ONESIGNAL_MERCHANT_API_KEY}`,
       },
       body: JSON.stringify({
         app_id: ONESIGNAL_MERCHANT_APP_ID,
         include_player_ids: [merchantPlayerId],
         headings: { tr: "Kurye Atandı!" },
         contents: { tr: `Sipariş #${order.order_number} için kurye yolda` },
       }),
     });
   } data: { orderId: "12345", type: "new_delivery" },
     }),
   });
   ```

5. **Set Environment Variables in Supabase:**
   - Dashboard → Settings → Edge Functions → Secrets
   - Add `ONESIGNAL_APP_ID`
   - Add `ONESIGNAL_REST_API_KEY`

6. **Testing:**
   - Send test notification from OneSignal dashboard
   - Verify player_id saved in push_tokens table
   - Test edge function with real order assignment

**Migration Checklist:**
- [ ] OneSignal account created
- [ ] OneSignal SDK added to all apps (courier, merchant, admin)
- [ ] Database schema updated (push_tokens table)
- [ ] Edge functions updated to use OneSignal API
- [ ] Environment variables configured
- [ ] Old FCM code removed
- [ ] Production testing completed

### Delivery Photo Capture
```dart
// Using image_picker
final ImagePicker _picker = ImagePicker();
final XFile? photo = await _picker.pickImage(
  source: ImageSource.camera,
  maxWidth: 1024,
  maxHeight: 1024,
  imageQuality: 85,
);

// Upload to Supabase Storage
await supabase.storage
  .from('delivery_photos')
  .upload('path/to/photo.jpg', File(photo.path));
```

### Order Status Flow (Courier Perspective)
1. Order appears in list with status `'ASSIGNED'`
2. Courier taps "Kabul Et" → status → `'ACCEPTED'`
3. Courier navigates to merchant → taps "Aldım" → status → `'PICKED_UP'`
4. Courier navigates to customer → taps "Teslim Et" → captures photo → status → `'DELIVERED'`

### Testing on Physical Device
**Android:**
```bash
# Enable USB debugging on device
adb devices  # Verify connection
cd onlog_courier_app/onlog_courier
flutter run
```

**iOS:**
```bash
# Connect iPhone, trust computer
cd onlog_courier_app/onlog_courier
flutter run
```

### Common Courier App Tasks

**Adding a new screen:**
1. Create file in `lib/courier/screens/new_screen.dart`
2. Add route in `CourierNavigationScreen` if needed
3. Use existing screens as templates for consistent UI

**Modifying map behavior:**
- See `lib/courier/screens/map_screen.dart`
- Google Maps controller initialization in `_MapScreenState`
- Custom markers defined in `_createMarkers()`

**Updating earnings calculation:**
- Service: `lib/services/earnings_service.dart` (if exists) OR direct Supabase queries
- Check `payment_transactions` table with `type='deliveryFee'`

**Debugging location issues:**
1. Check permissions: `PermissionHandler.checkPermissionStatus()`
2. Verify `AndroidManifest.xml` has location permissions
3. Check Supabase logs for location update errors
4. Use `CHECK_COURIER_LOCATION_LIVE.sql` to verify data

### Release Build Checklist
See `COURIER_GOOGLE_PLAY_HAZIRLIK.md` for full Google Play release process:
- [ ] Update version in `pubspec.yaml`
- [ ] Configure signing key: `onlog-courier-release.jks`
- [ ] Build release APK: `flutter build apk --release`
- [ ] Test on physical device
- [ ] Generate screenshots for Play Store
- [ ] Update app listing

### Important Files for Courier App
- `COURIER_APP_FINAL_REPORT.md` - Final feature summary
- `COURIER_GOOGLE_PLAY_HAZIRLIK.md` - Google Play release guide
- `COURIER_REALTIME_GUNCELLEMESI.md` - Realtime updates documentation
- `CHECK_COURIER_*.sql` - Diagnostic queries for courier debugging

---

## Testing & Debugging Workflows

### Diagnosing Database Issues
1. Use `CHECK_*.sql` files to inspect current state (e.g., `CHECK_COURIER_STATUS.sql`, `CHECK_WEBHOOK_LOGS_DETAILED.sql`)
2. Check Supabase Dashboard > Logs > Database for trigger execution
3. Verify RLS policies: `CHECK_RLS_POLICIES.sql` or similar
4. For location issues: `CHECK_COURIER_LOCATION_LIVE.sql`
5. For payment flow: `DEBUG_WALLET_DATA.sql`

### Common Debugging Commands
```sql
-- Check if trigger exists and is active
SELECT * FROM information_schema.triggers 
WHERE trigger_name LIKE '%your_trigger%';

-- View recent function logs in Supabase
-- Dashboard > Logs > Functions > Select function

-- Test commission calculation manually
SELECT * FROM commission_configs WHERE merchant_id IS NULL;
```

### Flutter Hot Reload Issues
If changes don't appear after hot reload with `onlog_shared`:
```bash
cd onlog_shared
flutter pub get
cd ../onlog_merchant_panel  # or other app
flutter clean
flutter pub get
flutter run
```
