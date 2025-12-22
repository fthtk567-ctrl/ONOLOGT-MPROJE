// Simple seeder utility (cleaned)
// Consolidated imports and removed duplicate placeholder class.
import 'package:onlog_shared/services/supabase_service.dart';

// Test verileri Supabase Dashboard'dan manuel eklenir

/// Test merchants, couriers ve delivery_requests ekler

/// NOT: Bu sadece test amaçlıdır, production'da kullanılmaz!/// Basit test verisi ekleyici - Supabase kullanarak/// Basit test verisi ekleyici - Supabase kullanarak

class SimpleSeeder {

  final _supabase = SupabaseService.client;/// Test merchants, couriers ve delivery_requests ekler/// Test merchants, couriers ve delivery_requests ekler



  /// Tüm test verilerini ekle/// NOT: Bu sadece test amaçlıdır, production'da kullanılmaz!class SimpleSeeder {

  Future<void> seedAll() async {

    print('🌱 Test verileri ekleniyor (Supabase)...');class SimpleSeeder {  final supabase = SupabaseService.client;

    

    try {  final supabase = SupabaseService.client;

      // 1. Test users (merchants) ekle

      final merchantIds = await seedMerchants();  /// Tüm test verilerini ekle (Auth olmadan)

      print('✅ ${merchantIds.length} merchant eklendi');

        /// Tüm test verilerini ekle  Future<void> seedAll() async {

      // 2. Test users (couriers) ekle

      final courierIds = await _seedCouriers();  Future<void> seedAll() async {    print('🌱 Test verileri ekleniyor (Auth bypass)...');

      print('✅ ${courierIds.length} kurye eklendi');

          print('🌱 Test verileri ekleniyor (Supabase)...');    

      // 3. Test delivery_requests ekle

      final deliveryIds = await _seedDeliveryRequests(merchantIds, courierIds);        try {

      print('✅ ${deliveryIds.length} teslimat isteği eklendi');

          try {      // 1. Restoranları ekle

      print('🎉 Test verileri başarıyla eklendi!');

            // 1. Test users (merchants) ekle      final restaurantIds = await _seedRestaurants();

    } catch (e) {

      print('❌ Hata: $e');      final merchantIds = await seedMerchants();      print('✅ ${restaurantIds.length} restoran eklendi');

      rethrow;

    }      print('✅ ${merchantIds.length} merchant eklendi');      

  }

            // 2. Kuryeleri ekle

  /// Merchant users ekle

  Future<List<String>> seedMerchants() async {      // 2. Test users (couriers) ekle      final courierIds = await _seedCouriers();

    final merchants = [

      {      final courierIds = await _seedCouriers();      print('✅ ${courierIds.length} kurye eklendi');

        'email': 'pizza@restaurant.com',

        'full_name': 'Pizza House',      print('✅ ${courierIds.length} kurye eklendi');      

        'role': 'merchant',

        'phone': '+90 216 555 1122',            // 3. Siparişleri ekle

        'business_name': 'Pizza House',

        'business_address': 'Bağdat Caddesi No: 250, Kadıköy, İstanbul',      // 3. Test delivery_requests ekle      final orderIds = await _seedOrders(restaurantIds, courierIds);

        'business_type': 'pizza',

        'location': {'lat': 40.9887, 'lng': 29.0303},      final deliveryIds = await _seedDeliveryRequests(merchantIds, courierIds);      print('✅ ${orderIds.length} sipariş eklendi');

        'commission_rate': 15.0,

        'is_active': true,      print('✅ ${deliveryIds.length} teslimat isteği eklendi');      

      },

      {            print('🎉 Test verileri başarıyla eklendi!');

        'email': 'burger@restaurant.com',

        'full_name': 'Burger King Local',      print('🎉 Test verileri başarıyla eklendi!');      print('');

        'role': 'merchant',

        'phone': '+90 212 444 5566',      print('');      print('📋 Manuel Kullanıcı Ekleme Gerekli:');

        'business_name': 'Burger King Local',

        'business_address': 'İstiklal Caddesi No: 150, Beyoğlu, İstanbul',      print('📋 Manuel Kullanıcı Ekleme:');      print('Firebase Console → Authentication → Add User:');

        'business_type': 'burger',

        'location': {'lat': 41.0369, 'lng': 28.9784},      print('Supabase Dashboard → Authentication → Add User:');      print('');

        'commission_rate': 12.0,

        'is_active': true,      print('');      print('1. admin@onlog.com / admin123 (superAdmin)');

      },

    ];      print('1. admin@onlog.com / admin123 (superAdmin)');      print('2. pizza@restaurant.com / pizza123 (restaurantOwner)');



    List<String> merchantIds = [];      print('2. pizza@restaurant.com / pizza123 (merchant)');      print('3. burger@restaurant.com / burger123 (restaurantOwner)');



    for (var merchant in merchants) {      print('3. burger@restaurant.com / burger123 (merchant)');      print('4. courier1@onlog.com / courier123 (courier)');

      final response = await supabase.from('users').insert(merchant).select('id').single();

      final userId = response['id'] as String;      print('4. courier1@onlog.com / courier123 (courier)');      print('5. courier2@onlog.com / courier123 (courier)');



      merchantIds.add(userId);      print('5. courier2@onlog.com / courier123 (courier)');      print('6. courier3@onlog.com / courier123 (courier)');

      print('  ✓ ${merchant['full_name']}');

    }            



    return merchantIds;    } catch (e) {    } catch (e) {

  }

      print('❌ Hata: $e');      print('❌ Hata: $e');

  /// Courier users ekle

  Future<List<String>> seedCouriers() async {      rethrow;      rethrow;

    final couriers = [

      {    }    }

        'email': 'courier1@onlog.com',

        'full_name': 'Ali Kaya',  }  }

        'role': 'courier',

        'phone': '+90 555 111 2233',

        'vehicle_type': 'motorcycle',

        'vehicle_plate': '34 ABC 123',  /// Merchant users ekle  /// Restoranları ekle

        'is_available': true,

        'is_active': true,  Future<List<String>> seedMerchants() async {  Future<Map<String, String>> seedRestaurants() async {

        'current_location': {'lat': 40.9910, 'lng': 29.0320},

        'average_rating': 4.8,    final merchants = [    final restaurants = [

        'total_ratings': 45,

        'total_deliveries': 120,      {      {

      },

      {        'email': 'pizza@restaurant.com',        'name': 'Pizza House',

        'email': 'courier2@onlog.com',

        'full_name': 'Veli Şahin',        'full_name': 'Pizza House',        'type': 'pizza',

        'role': 'courier',

        'phone': '+90 555 444 5566',        'role': 'merchant',        'phone': '+90 216 555 1122',

        'vehicle_type': 'bicycle',

        'is_available': false,        'phone': '+90 216 555 1122',        'email': 'info@pizzahouse.com',

        'is_active': true,

        'current_location': {'lat': 41.0380, 'lng': 28.9800},        'business_name': 'Pizza House',        'address': 'Bağdat Caddesi No: 250, Kadıköy, İstanbul',

        'average_rating': 4.5,

        'total_ratings': 32,        'business_address': 'Bağdat Caddesi No: 250, Kadıköy, İstanbul',        'latitude': 40.9887,

        'total_deliveries': 85,

      },        'business_type': 'pizza',        'longitude': 29.0303,

    ];

        'location': {'lat': 40.9887, 'lng': 29.0303},        'platformIntegrations': {

    List<String> courierIds = [];

        'commission_rate': 15.0,          'trendyol': {

    for (var courier in couriers) {

      final response = await _supabase.from('users').insert(courier).select('id').single();        'is_active': true,            'apiKey': 'trendyol_test_key_1',

      final userId = response['id'] as String;

      },            'storeId': 'pizza-house-123',

      courierIds.add(userId);

      print('  ✓ ${courier['full_name']}');      {            'isActive': true,

    }

        'email': 'burger@restaurant.com',          },

    return courierIds;

  }        'full_name': 'Burger King Local',          'yemeksepeti': {



  /// Test delivery_requests ekle        'role': 'merchant',            'apiKey': 'yemeksepeti_test_key_1',

  Future<List<String>> _seedDeliveryRequests(

    List<String> merchantIds,        'phone': '+90 212 444 5566',            'storeId': 'pizzahouse456',

    List<String> courierIds,

  ) async {        'business_name': 'Burger King Local',            'isActive': true,

    final now = DateTime.now();

            'business_address': 'İstiklal Caddesi No: 150, Beyoğlu, İstanbul',          },

    final deliveries = [

      {        'business_type': 'burger',        },

        'merchant_id': merchantIds[0],

        'courier_id': courierIds[0],        'location': {'lat': 41.0369, 'lng': 28.9784},      },

        'pickup_address': 'Bağdat Caddesi No: 250, Kadıköy',

        'delivery_address': 'Acıbadem Cad. No: 15, Kadıköy',        'commission_rate': 12.0,      {

        'pickup_location': {'lat': 40.9887, 'lng': 29.0303},

        'delivery_location': {'lat': 40.9920, 'lng': 29.0350},        'is_active': true,        'name': 'Burger King Local',

        'package_description': '2x Margarita Pizza, 1x Coca Cola',

        'delivery_fee': 25.0,      },        'type': 'burger',

        'status': 'delivered',

        'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),    ];        'phone': '+90 212 444 5566',

        'delivered_at': now.subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),

      },        'email': 'info@burgerkinglocal.com',

      {

        'merchant_id': merchantIds[1],    List<String> merchantIds = [];        'address': 'İstiklal Caddesi No: 150, Beyoğlu, İstanbul',

        'courier_id': courierIds[1],

        'pickup_address': 'İstiklal Caddesi No: 150, Beyoğlu',        'latitude': 41.0369,

        'delivery_address': 'Taksim Meydanı No: 5, Beyoğlu',

        'pickup_location': {'lat': 41.0369, 'lng': 28.9784},    for (var merchant in merchants) {        'longitude': 28.9784,

        'delivery_location': {'lat': 41.0370, 'lng': 28.9850},

        'package_description': '3x Whopper Menu',      // Generate UUID manually from email for consistency        'platformIntegrations': {

        'delivery_fee': 20.0,

        'status': 'on_the_way',      final response = await supabase.from('users').insert(merchant).select('id').single();          'getir': {

        'created_at': now.subtract(const Duration(minutes: 15)).toIso8601String(),

        'picked_up_at': now.subtract(const Duration(minutes: 5)).toIso8601String(),      final userId = response['id'] as String;            'apiKey': 'getir_test_key_1',

      },

    ]            'storeId': 'burger-local-789',



    List<String> deliveryIds = [];      merchantIds.add(userId);            'isActive': true,



    for (var delivery in deliveries) {      print('  ✓ ${merchant['full_name']}');          },

      final response = await supabase.from('delivery_requests').insert(delivery).select('id').single();

      final deliveryId = response['id'] as String;    }        },



      deliveryIds.add(deliveryId);      },

      print('  ✓ ${delivery['status']} - ${delivery['package_description']}');

    }    return merchantIds;    ]



    return deliveryIds;  }

  }

    Map<String, String> restaurantIds = {};

  /// Tüm test verilerini temizle

  Future<void> cleanAll() async {  /// Courier users ekle

    print('🧹 Test verileri temizleniyor...');

      Future<List<String>> seedCouriers() async {    for (var restaurant in restaurants) {

    try {

      await _supabase.from('delivery_requests').delete().neq('id', '00000000-0000-0000-0000-000000000000');    final couriers = [      final docRef = _firestore.collection('restaurants').doc();

      print('✅ delivery_requests temizlendi');

            {      final restaurantId = docRef.id;

      await _supabase.from('users').delete().like('email', '%@restaurant.com');

      await _supabase.from('users').delete().like('email', 'courier%@onlog.com');        'email': 'courier1@onlog.com',

      print('✅ Test users temizlendi');

              'full_name': 'Ali Kaya',      await docRef.set({

      print('🎉 Temizlik tamamlandı!');

              'role': 'courier',        'name': restaurant['name'],

    } catch (e) {

      print('❌ Hata: $e');        'phone': '+90 555 111 2233',        'ownerId': null, // Manuel olarak eklenecek

      rethrow;

    }        'vehicle_type': 'motorcycle',        'type': restaurant['type'],

  }

}        'vehicle_plate': '34 ABC 123',        'phone': restaurant['phone'],


        'is_available': true,        'email': restaurant['email'],

        'is_active': true,        'address': restaurant['address'],

        'current_location': {'lat': 40.9910, 'lng': 29.0320},        'location': {

        'average_rating': 4.8,          'latitude': restaurant['latitude'],

        'total_ratings': 45,          'longitude': restaurant['longitude'],

        'total_deliveries': 120,        },

      },        'platformIntegrations': restaurant['platformIntegrations'],

      {        'isActive': true,

        'email': 'courier2@onlog.com',        'rating': 4.5,

        'full_name': 'Veli Şahin',        'totalOrders': 0,

        'role': 'courier',        'totalRevenue': 0.0,

        'phone': '+90 555 444 5566',        'createdAt': FieldValue.serverTimestamp(),

        'vehicle_type': 'bicycle',        'updatedAt': FieldValue.serverTimestamp(),

        'vehicle_plate': null,      })

        'is_available': false,

        'is_active': true,      restaurantIds[restaurant['name'] as String] = restaurantId;

        'current_location': {'lat': 41.0380, 'lng': 28.9800},      print('  ✓ ${restaurant['name']}');

        'average_rating': 4.5,    }

        'total_ratings': 32,

        'total_deliveries': 85,    return restaurantIds;

      },  }

      {

        'email': 'courier3@onlog.com',  /// Kuryeleri ekle

        'full_name': 'Ayşe Çelik',  Future<Map<String, String>> _seedCouriers() async {

        'role': 'courier',    final couriers = [

        'phone': '+90 555 777 8899',      {

        'vehicle_type': 'motorcycle',        'name': 'Ali Kaya',

        'vehicle_plate': '34 XYZ 789',        'vehicleType': 'motorcycle',

        'is_available': true,        'vehiclePlate': '34 ABC 123',

        'is_active': true,        'status': 'available',

        'current_location': {'lat': 40.9950, 'lng': 29.0400},        'latitude': 40.9910,

        'average_rating': 4.9,        'longitude': 29.0320,

        'total_ratings': 67,      },

        'total_deliveries': 156,      {

      },        'name': 'Veli Şahin',

    ];        'vehicleType': 'bicycle',

        'vehiclePlate': null,

    List<String> courierIds = [];        'status': 'delivering',

        'latitude': 41.0380,

    for (var courier in couriers) {        'longitude': 28.9800,

      final response = await _supabase.from('users').insert(courier).select('id').single();      },

      final userId = response['id'] as String;      {

        'name': 'Ayşe Çelik',

      courierIds.add(userId);        'vehicleType': 'motorcycle',

      print('  ✓ ${courier['full_name']}');        'vehiclePlate': '34 XYZ 789',

    }        'status': 'offline',

        'latitude': 40.9950,

    return courierIds;        'longitude': 29.0400,

  }      },

    ];

  /// Test delivery_requests ekle

  Future<List<String>> _seedDeliveryRequests(    Map<String, String> courierIds = {};

    List<String> merchantIds,

    List<String> courierIds,    for (var courier in couriers) {

  ) async {      final docRef = _firestore.collection('couriers').doc();

    final now = DateTime.now();      final courierId = docRef.id;

    

    final deliveries = [      await docRef.set({

      {        'userId': null, // Manuel olarak eklenecek

        'merchant_id': merchantIds[0],        'vehicleType': courier['vehicleType'],

        'courier_id': courierIds[0],        'vehiclePlate': courier['vehiclePlate'],

        'pickup_address': 'Bağdat Caddesi No: 250, Kadıköy',        'status': courier['status'],

        'delivery_address': 'Acıbadem Cad. No: 15, Kadıköy',        'currentLocation': {

        'pickup_location': {'lat': 40.9887, 'lng': 29.0303},          'latitude': courier['latitude'],

        'delivery_location': {'lat': 40.9920, 'lng': 29.0350},          'longitude': courier['longitude'],

        'package_description': '2x Margarita Pizza, 1x Coca Cola',        },

        'delivery_fee': 25.0,        'isActive': true,

        'status': 'delivered',        'rating': 4.7,

        'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),        'totalDeliveries': 0,

        'delivered_at': now.subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),        'totalEarnings': 0.0,

      },        'todayDeliveries': 0,

      {        'createdAt': FieldValue.serverTimestamp(),

        'merchant_id': merchantIds[1],        'updatedAt': FieldValue.serverTimestamp(),

        'courier_id': courierIds[1],      });

        'pickup_address': 'İstiklal Caddesi No: 150, Beyoğlu',

        'delivery_address': 'Taksim Meydanı No: 5, Beyoğlu',      courierIds[courier['name'] as String] = courierId;

        'pickup_location': {'lat': 41.0369, 'lng': 28.9784},      print('  ✓ Kurye ${courier['name']} (${courier['status']})');

        'delivery_location': {'lat': 41.0370, 'lng': 28.9850},    }

        'package_description': '3x Whopper Menu',

        'delivery_fee': 20.0,    return courierIds;

        'status': 'on_the_way',  }

        'created_at': now.subtract(Duration(minutes = 15)).toIso8601String(),

        'picked_up_at': now.subtract(Duration(minutes = 5)).toIso8601String(),  /// Siparişleri ekle

      },  Future<List<String>> _seedOrders(

      {     = merchantIds[0],

        'courier_id' = courierIds[2],  ) async {

        'pickup_address': 'Bağdat Caddesi No: 250, Kadıköy',    final orders = [

        'delivery_address': 'Suadiye Sahil No: 45, Kadıköy',      {

        'pickup_location': {'lat': 40.9887, 'lng': 29.0303},        'restaurant': 'Pizza House',

        'delivery_location': {'lat': 40.9680, 'lng': 29.1050},        'courierName': null,

        'package_description': '1x Pepperoni Pizza, 2x Fanta',        'platform': 'trendyol',

        'delivery_fee': 30.0,        'platformOrderId': 'TRND-001',

        'status': 'assigned',        'status': 'pending',

        'created_at': now.subtract(const Duration(minutes': 5)).toIso8601String(),        'customerName': 'Zeynep Yıldız',

      },        'customerPhone': '+90 532 111 2233',

    ];        'deliveryAddress': 'Koşuyolu Mahallesi, Kadıköy, İstanbul',

        'deliveryLat': 40.9820,

    List<String> deliveryIds = [];        'deliveryLng': 29.0250,

        'items': [

    for (var delivery in deliveries) {          {'name': 'Margherita Pizza', 'quantity': 2, 'price': 120.0},

      final response = await _supabase.from('delivery_requests').insert(delivery).select('id').single();          {'name': 'Coca Cola 1L', 'quantity': 1, 'price': 25.0},

      final deliveryId = response['id'] as String;        ],

        'subtotal': 265.0,

      deliveryIds.add(deliveryId);        'deliveryFee': 15.0,

      print('  ✓ ${delivery['status']} - ${delivery['package_description']}');        'total': 280.0,

    }      },

      {

    return deliveryIds;        'restaurant': 'Pizza House',

  }        'courierName': null,

        'platform': 'yemeksepeti',

  /// Tüm test verilerini temizle        'platformOrderId': 'YS-002',

  Future<void> cleanAll() async {        'status': 'pending',

    print('🧹 Test verileri temizleniyor...');        'customerName': 'Can Arslan',

            'customerPhone': '+90 533 444 5566',

    try {        'deliveryAddress': 'Fenerbahçe, Kadıköy, İstanbul',

      // Delivery requests'leri sil        'deliveryLat': 40.9650,

      await _supabase.from('delivery_requests').delete().neq('id', '00000000-0000-0000-0000-000000000000');        'deliveryLng': 29.0380,

      print('✅ delivery_requests temizlendi');        'items': [

                {'name': 'Pepperoni Pizza', 'quantity': 1, 'price': 140.0},

      // Test users'ları sil (email pattern ile)        ],

      await _supabase.from('users').delete().like('email', '%@restaurant.com');        'subtotal': 140.0,

      await _supabase.from('users').delete().like('email', 'courier%@onlog.com');        'deliveryFee': 12.0,

      print('✅ Test users temizlendi');        'total': 152.0,

            },

      print('🎉 Temizlik tamamlandı!');      {

              'restaurant': 'Burger King Local',

    } catch (e) {        'courierName': 'Veli Şahin',

      print('❌ Hata: $e');        'platform': 'getir',

      rethrow;        'platformOrderId': 'GTR-003',

    }        'status': 'pickedUp',

  }        'customerName': 'Elif Kaya',

}        'customerPhone': '+90 534 777 8899',

        'deliveryAddress': 'Taksim Meydanı, Beyoğlu, İstanbul',
        'deliveryLat': 41.0369,
        'deliveryLng': 28.9850,
        'items': [
          {'name': 'Whopper Menu', 'quantity': 2, 'price': 180.0},
          {'name': 'Chicken Royale', 'quantity': 1, 'price': 90.0},
        ],
        'subtotal': 270.0,
        'deliveryFee': 18.0,
        'total': 288.0,
      },
      {
        'restaurant': 'Pizza House',
        'courierName': 'Ali Kaya',
        'platform': 'trendyol',
        'platformOrderId': 'TRND-004',
        'status': 'preparing',
        'customerName': 'Ahmet Yılmaz',
        'customerPhone': '+90 535 222 3344',
        'deliveryAddress': 'Moda, Kadıköy, İstanbul',
        'deliveryLat': 40.9850,
        'deliveryLng': 29.0290,
        'items': [
          {'name': 'Vegetarian Pizza', 'quantity': 1, 'price': 110.0},
        ],
        'subtotal': 110.0,
        'deliveryFee': 10.0,
        'total': 120.0,
      },
      {
        'restaurant': 'Burger King Local',
        'courierName': null,
        'platform': 'manuel',
        'platformOrderId': null,
        'status': 'delivered',
        'customerName': 'Mehmet Öz',
        'customerPhone': '+90 536 999 0011',
        'deliveryAddress': 'Cihangir, Beyoğlu, İstanbul',
        'deliveryLat': 41.0340,
        'deliveryLng': 28.9820,
        'items': [
          {'name': 'Big King XXL', 'quantity': 1, 'price': 150.0},
        ],
        'subtotal': 150.0,
        'deliveryFee': 15.0,
        'total': 165.0,
      },
    ];

    List<String> orderIds = [];

    for (var order in orders) {
      final docRef = _firestore.collection('orders').doc();
      final orderId = docRef.id;

      final restaurantId = restaurantIds[order['restaurant']];
      final courierId = order['courierName'] != null
          ? courierIds[order['courierName']]
          : null;

      await docRef.set({
        'restaurantId': restaurantId,
        'courierId': courierId,
        'platform': order['platform'],
        'platformOrderId': order['platformOrderId'],
        'status': order['status'],
        'customer': {
          'name': order['customerName'],
          'phone': order['customerPhone'],
        },
        'deliveryAddress': {
          'fullAddress': order['deliveryAddress'],
          'location': {
            'latitude': order['deliveryLat'],
            'longitude': order['deliveryLng'],
          },
        },
        'items': order['items'],
        'subtotal': order['subtotal'],
        'deliveryFee': order['deliveryFee'],
        'totalAmount': order['total'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      orderIds.add(orderId);
      print('  ✓ Sipariş ${order['platformOrderId'] ?? orderId.substring(0, 8)} (${order['status']})');
    }

    return orderIds;
  }

  /// Tüm test verilerini sil
  Future<void> clearAll() async {
    print('🗑️  Test verileri siliniyor...');

    try {
      // Siparişleri sil
      final orders = await _firestore.collection('orders').get();
      for (var doc in orders.docs) {
        await doc.reference.delete();
      }
      print('✅ ${orders.size} sipariş silindi');

      // Kuryeleri sil
      final couriers = await _firestore.collection('couriers').get();
      for (var doc in couriers.docs) {
        await doc.reference.delete();
      }
      print('✅ ${couriers.size} kurye silindi');

      // Restoranları sil
      final restaurants = await _firestore.collection('restaurants').get();
      for (var doc in restaurants.docs) {
        await doc.reference.delete();
      }
      print('✅ ${restaurants.size} restoran silindi');

      print('🎉 Test verileri temizlendi!');
    } catch (e) {
      print('❌ Hata: $e');
      rethrow;
    }
  }
}
