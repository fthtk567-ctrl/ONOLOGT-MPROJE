class SupabaseConfig {
  // ONLOG Production Supabase credentials
  static const String supabaseUrl = 'https://oilldfyywtzybrmpyixx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NzI4MjksImV4cCI6MjA3NjI0ODgyOX0.kwTQgWja1VJBNA4sXEbznmv9LMoyO_5rioaTaQXvKsM';
  
  // Core Tables
  static const String TABLE_USERS = 'users';
  static const String TABLE_ORDERS = 'orders';
  static const String TABLE_FINANCIAL_TRANSACTIONS = 'financial_transactions';
  
  // Legal & Compliance
  static const String TABLE_LEGAL_DOCUMENTS = 'legal_documents';
  static const String TABLE_USER_CONSENTS = 'user_consents';
  
  // Platform Integration
  static const String TABLE_TRENDYOL_CREDENTIALS = 'trendyol_credentials';
  static const String TABLE_PLATFORM_ORDERS = 'platform_orders';
  static const String TABLE_ONLOG_MERCHANT_MAPPING = 'onlog_merchant_mapping';
  
  // Payment Systems
  static const String TABLE_PAYMENT_TRANSACTIONS = 'payment_transactions';
  static const String TABLE_MERCHANT_WALLETS = 'merchant_wallets';
  static const String TABLE_WALLET_TRANSACTIONS = 'wallet_transactions';
  
  // Risk & Security
  static const String TABLE_RISK_ALERTS = 'risk_alerts';
  
  // Configuration
  static const String TABLE_COMMISSION_CONFIGS = 'commission_configs';
  static const String TABLE_APP_SETTINGS = 'app_settings';
  
  // Legacy (backward compatibility)
  static const String usersTable = TABLE_USERS;
  static const String ordersTable = TABLE_ORDERS;
  static const String financialTransactionsTable = TABLE_FINANCIAL_TRANSACTIONS;
}