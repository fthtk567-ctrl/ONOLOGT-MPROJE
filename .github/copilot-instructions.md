# ONLOG - AI Coding Agent Instructions

## System Overview
ONLOG is a **three-app Flutter courier/order management platform** for local merchants in Turkey. All apps share a **Supabase backend** with an automated financial payment system powered by PostgreSQL triggers.

### Project Structure
```
onlog_projects/
├── onlog_shared/           # Shared package: models, services, Supabase client
├── onlog_merchant_panel/   # Merchant app (multi-platform: Android, iOS, Web, Desktop)
├── onlog_courier_app/      # Courier app (Android, iOS)
│   └── onlog_courier/      # Actual Flutter project (nested directory)
├── onlog_admin_panel/      # Admin app (Web only)
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
- **Key Tables:** `users`, `orders`, `payment_transactions`, `merchant_wallets`, `courier_wallets`, `commission_configs`

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
```powershell
cd c:\onlog_projects\onlog_merchant_panel
flutter pub get
flutter run -d chrome        # Web
flutter run                   # Connected device
```

**Courier App (mobile):**
```powershell
cd c:\onlog_projects\onlog_courier_app\onlog_courier  # Note: nested directory!
flutter pub get
flutter run                   # Android/iOS device
```

**Admin Panel (web-only):**
```powershell
cd c:\onlog_projects\onlog_admin_panel
flutter pub get
flutter run -d chrome
```

### Adding Dependencies
1. Update the relevant app's `pubspec.yaml` (merchant/courier/admin)
2. If dependency is needed across apps, add to `onlog_shared/pubspec.yaml`
3. Run `flutter pub get` in the app directory

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
- Trendyol/Getir API credentials stored in `trendyol_credentials` table
- External orders imported to `platform_orders` table
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
- `yemek-app-order-webhook` - Yemek App external order integration (uses `onlog_merchant_mapping` table)
- `send-courier-notification`, `send-fcm-notification` - FCM push notifications
- `send-push-notification` - Generic notification delivery

**Deployment pattern:**
```powershell
C:\supabase\supabase.exe functions deploy <function-name> --project-ref oilldfyywtzybrmpyixx
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

**Testing webhooks locally (PowerShell):**
```powershell
Invoke-RestMethod -Uri "https://oilldfyywtzybrmpyixx.supabase.co/functions/v1/yemek-app-order-webhook" `
  -Method Post `
  -Headers @{"Authorization"="Bearer YOUR_API_KEY"; "Content-Type"="application/json"} `
  -Body '{"restaurant_id":"R-TEST-001","order_id":"TEST-123",...}'
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
- ❌ Don't use Firebase SDK - this project uses Supabase
- ❌ Don't modify `onlog_shared` without running `flutter pub get` in all apps
- ❌ Don't hardcode user IDs or credentials - use Supabase Auth
- ❌ Don't create separate copies of models - use `onlog_shared` exports

## When You're Stuck

1. Check the relevant `*_RAPORU.md` files - they document completed features
2. Review `SISTEM_AKIS_SEMASI.md` for system-wide data flows
3. Inspect similar screens in the same app for UI patterns
4. For payment issues, see `OTOMATIK_ODEME_SISTEMI.md`
5. For Supabase queries, check `onlog_shared/lib/services/` implementations

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
```powershell
cd c:\onlog_projects\onlog_shared
flutter pub get
cd ..\onlog_merchant_panel  # or other app
flutter clean
flutter pub get
flutter run
```
