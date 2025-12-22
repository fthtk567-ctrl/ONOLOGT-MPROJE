import 'package:flutter_test/flutter_test.dart';
import 'package:onlog_shared/onlog_shared.dart';

void main() {
  test('Order model test', () {
    // Basit test - Order modeli düzgün import ediliyor mu?
    expect(OrderStatus.pending, isNotNull);
    expect(OrderPlatform.trendyol, isNotNull);
  });
}

