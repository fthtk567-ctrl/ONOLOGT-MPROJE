import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/location_picker_map.dart';

/// Restoran/Market Kayıt Ekranı
/// İşletmeler buradan sisteme başvuru yapar ve komisyon ayarlarını belirler
class MerchantRegistrationScreen extends StatefulWidget {
  const MerchantRegistrationScreen({super.key});

  @override
  State<MerchantRegistrationScreen> createState() => _MerchantRegistrationScreenState();
}

class _MerchantRegistrationScreenState extends State<MerchantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // İşletme Bilgileri
  String _businessType = 'restaurant'; // restaurant, market, cafe
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Adres Bilgileri
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  // 🗺️ Seçilen konum koordinatları
  double? _selectedLatitude;
  double? _selectedLongitude;

  // Komisyon Ayarları
  String _commissionType = 'percentage'; // percentage, perOrder, hybrid
  final _commissionRateController = TextEditingController();
  final _perOrderFeeController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  final _deliveryRadiusController = TextEditingController();

  // Minimum/Maximum Limitler
  static const double minCommissionRate = 15.0;  // Minimum %15
  static const double maxCommissionRate = 30.0;  // Maximum %30
  static const double minPerOrderFee = 5.0;      // Minimum 5₺
  static const double maxPerOrderFee = 25.0;     // Maximum 25₺

  // Ödeme Döngüsü
  String _paymentCycle = 'weekly'; // weekly, biweekly, monthly
  int _paymentDay = 1;

  // Banka Bilgileri
  final _bankNameController = TextEditingController();
  final _ibanController = TextEditingController();
  final _accountHolderController = TextEditingController();

  // Vergi Bilgileri
  final _taxNumberController = TextEditingController();
  final _tradeRegistryController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşletme Kaydı'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _currentStep > 0
                  ? () => setState(() => _currentStep--)
                  : null,
              steps: [
                // ADIM 1: İşletme Bilgileri
                Step(
                  title: const Text('İşletme Bilgileri'),
                  isActive: _currentStep >= 0,
                  content: _buildBusinessInfoStep(),
                ),

                // ADIM 2: Adres Bilgileri
                Step(
                  title: const Text('Adres Bilgileri'),
                  isActive: _currentStep >= 1,
                  content: _buildAddressInfoStep(),
                ),

                // ADIM 3: Komisyon Ayarları
                Step(
                  title: const Text('Komisyon Ayarları'),
                  isActive: _currentStep >= 2,
                  content: _buildCommissionSettingsStep(),
                ),

                // ADIM 4: Ödeme Bilgileri
                Step(
                  title: const Text('Ödeme Bilgileri'),
                  isActive: _currentStep >= 3,
                  content: _buildPaymentInfoStep(),
                ),

                // ADIM 5: Vergi & Banka
                Step(
                  title: const Text('Vergi & Banka'),
                  isActive: _currentStep >= 4,
                  content: _buildTaxBankStep(),
                ),
              ],
            ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İşletme Türü',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _businessType,
          decoration: const InputDecoration(
            labelText: 'Kategori Seçin',
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: 'restaurant',
              child: Row(
                children: [
                  Icon(Icons.restaurant, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('🍕 Restoran'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'market',
              child: Row(
                children: [
                  Icon(Icons.store, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('🏪 Market'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'cafe',
              child: Row(
                children: [
                  Icon(Icons.local_cafe, color: Colors.brown),
                  SizedBox(width: 8),
                  Text('☕ Kafe'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'bakery',
              child: Row(
                children: [
                  Icon(Icons.bakery_dining, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('🥐 Fırın / Pastane'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'grocery',
              child: Row(
                children: [
                  Icon(Icons.shopping_basket, color: Colors.green),
                  SizedBox(width: 8),
                  Text('🥗 Manav / Şarküteri'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'hardware',
              child: Row(
                children: [
                  Icon(Icons.hardware, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('🔧 Hırdavat'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'pharmacy',
              child: Row(
                children: [
                  Icon(Icons.local_pharmacy, color: Colors.red),
                  SizedBox(width: 8),
                  Text('💊 Eczane'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'butcher',
              child: Row(
                children: [
                  Icon(Icons.set_meal, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('🥩 Kasap'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'florist',
              child: Row(
                children: [
                  Icon(Icons.local_florist, color: Colors.pink),
                  SizedBox(width: 8),
                  Text('🌸 Çiçekçi'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'petshop',
              child: Row(
                children: [
                  Icon(Icons.pets, color: Colors.purple),
                  SizedBox(width: 8),
                  Text('🐾 Pet Shop'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'industrial',
              child: Row(
                children: [
                  Icon(Icons.factory, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text('🏭 Sanayici / Toptancı'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'other',
              child: Row(
                children: [
                  Icon(Icons.business, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('📦 Diğer'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _businessType = value);
            }
          },
          validator: (v) => v == null ? 'İşletme türü seçin' : null,
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'İşletme Adı',
                  prefixIcon: Icon(Icons.business),
                  hintText: 'Örn: Pizza Palace',
                ),
                validator: (v) => v?.isEmpty ?? true ? 'İşletme adı gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Yetkili Kişi',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Yetkili adı gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Telefon gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.isEmpty ?? true ? 'E-posta gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock),
                  hintText: 'En az 6 karakter',
                  helperText: '⚠️ Şifre en az 6 karakter olmalıdır',
                  helperStyle: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return '❌ Şifre gerekli';
                  }
                  if (v.length < 6) {
                    return '❌ Şifre en az 6 karakter olmalıdır!';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📍 İNTERAKTİF HARİTA - KOnum seçme
        const Text(
          '📍 İşletmenizin Konumunu Seçin',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Haritaya tıklayarak işletmenizin tam konumunu belirleyin. Adres otomatik doldurulacak.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        LocationPickerMap(
          initialLocation: LatLng(37.8667, 32.4833), // Konya merkez
          onLocationSelected: (location, address, addressComponents) {
            setState(() {
              _selectedLatitude = location.latitude;
              _selectedLongitude = location.longitude;
              _addressController.text = address;
              
              // Adres componentlerinden İl/İlçe/Posta Kodu al
              if (addressComponents != null) {
                _cityController.text = addressComponents['city'] ?? '';
                _districtController.text = addressComponents['district'] ?? '';
                _postalCodeController.text = addressComponents['postalCode'] ?? '';
                
                debugPrint('📍 İl: ${addressComponents['city']}, İlçe: ${addressComponents['district']}, Posta: ${addressComponents['postalCode']}');
              }
            });
            debugPrint('✅ Konum seçildi: ${location.latitude}, ${location.longitude}');
          },
        ),
        
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        
        // ✍️ MANUEL ADRES GİRİŞİ (Opsiyonel düzeltme)
        const Text(
          '✍️ Adres Bilgileri (Düzeltme Yapabilirsiniz)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Adres',
            prefixIcon: Icon(Icons.location_on),
            hintText: 'Haritadan otomatik dolduruldu',
          ),
          maxLines: 2,
          validator: (v) => v?.isEmpty ?? true ? 'Adres gerekli' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'İl',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'İlçe',
                  prefixIcon: Icon(Icons.map),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _postalCodeController,
          decoration: const InputDecoration(
            labelText: 'Posta Kodu (Opsiyonel)',
            prefixIcon: Icon(Icons.markunread_mailbox),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _deliveryRadiusController,
          decoration: const InputDecoration(
            labelText: 'Teslimat Yarıçapı (km)',
            prefixIcon: Icon(Icons.my_location),
            hintText: 'Örn: 5',
            helperText: 'İşletmenizden kaç km mesafede teslimat yapabilirsiniz?',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildCommissionSettingsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Komisyon Sistemini Seçin',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Firma yöneticisi ile anlaştığınız komisyon şeklini seçin.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // ─────────────────────────────────────────────────────────
        // OPSİYON 1: YÜZDE KOMİSYON
        // ─────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _commissionType == 'percentage' ? Colors.blue : Colors.grey.shade300,
              width: _commissionType == 'percentage' ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RadioListTile<String>(
            title: const Row(
              children: [
                Icon(Icons.percent, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Sipariş Bazlı Yüzde Komisyon',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            subtitle: const Text('Her siparişin toplam tutarından belirli bir yüzde'),
            value: 'percentage',
            groupValue: _commissionType,
            onChanged: (value) => setState(() => _commissionType = value!),
          ),
        ),

        if (_commissionType == 'percentage') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ÖNEMLİ UYARI - KOMİSYON ORANI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Firma yöneticisi ile yaptığınız anlaşmadaki komisyon yüzdesini girdiğinizden emin olun. '
                  'Platform üzerinden aldığınız her sipariş için bu yüzde oranında komisyon kesintisi yapılacaktır.\n\n'
                  'Hatalı veya gerçeğe aykırı komisyon oranı girişlerinde başvurunuz onaylanmayabilir. '
                  'Herhangi bir yanlışlık, anlaşmazlık veya itiraz durumunda mutlaka destek ekibimizle iletişime geçin.\n\n'
                  '💡 Örnek: %20 komisyon oranı ile 100₺\'lik siparişte 80₺ size, 20₺ platform komisyonu olarak kesilir.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commissionRateController,
            decoration: InputDecoration(
              labelText: 'Komisyon Oranı',
              hintText: 'Örn: 20',
              prefixIcon: const Icon(Icons.percent),
              suffixText: '%',
              helperText: 'Minimum: %$minCommissionRate - Maximum: %$maxCommissionRate',
              helperStyle: const TextStyle(color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Komisyon oranı gerekli';
              }
              final rate = double.tryParse(value);
              if (rate == null) {
                return 'Geçerli bir sayı girin';
              }
              if (rate < minCommissionRate || rate > maxCommissionRate) {
                return 'Komisyon %$minCommissionRate - %$maxCommissionRate arasında olmalı';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          if (_commissionRateController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate, size: 20, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildCommissionExample(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],

        const SizedBox(height: 24),

        // ─────────────────────────────────────────────────────────
        // OPSİYON 2: SİPARİŞ BAŞI SABİT ÜCRET
        // ─────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _commissionType == 'perOrder' ? Colors.orange : Colors.grey.shade300,
              width: _commissionType == 'perOrder' ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RadioListTile<String>(
            title: const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Sipariş Başı Sabit Ücret',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            subtitle: const Text('Her sipariş için sabit tutar (sipariş tutarından bağımsız)'),
            value: 'perOrder',
            groupValue: _commissionType,
            onChanged: (value) => setState(() => _commissionType = value!),
          ),
        ),

        if (_commissionType == 'perOrder') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ÖNEMLİ UYARI - SİPARİŞ BAŞI ÜCRET',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Firma yöneticisi ile anlaştığınız sipariş başı ücreti girdiğinizden emin olun. '
                  'Bu ücret, sipariş tutarından bağımsız olarak her sipariş için sabit olarak uygulanır.\n\n'
                  'Hatalı tutar girişlerinde başvurunuz reddedilebilir. Anlaşmazlık durumunda '
                  'mutlaka destek ekibimiz ile iletişime geçin.\n\n'
                  '💡 Örnek: 10₺ sipariş ücreti ile 50₺\'lik siparişte 40₺ size, 10₺ platform ücreti olarak kesilir.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _perOrderFeeController,
            decoration: InputDecoration(
              labelText: 'Sipariş Başı Ücret',
              hintText: 'Örn: 10',
              prefixIcon: const Icon(Icons.monetization_on),
              suffixText: '₺',
              helperText: 'Minimum: $minPerOrderFee₺ - Maximum: $maxPerOrderFee₺',
              helperStyle: const TextStyle(color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Sipariş ücreti gerekli';
              }
              final fee = double.tryParse(value);
              if (fee == null) {
                return 'Geçerli bir tutar girin';
              }
              if (fee < minPerOrderFee || fee > maxPerOrderFee) {
                return 'Ücret $minPerOrderFee₺ - $maxPerOrderFee₺ arasında olmalı';
              }
              return null;
            },
          ),
        ],

        const SizedBox(height: 24),

        // Minimum Sipariş Tutarı (Her iki opsiyon için ortak)
        TextFormField(
          controller: _minimumOrderController,
          decoration: const InputDecoration(
            labelText: 'Minimum Sipariş Tutarı',
            hintText: 'Örn: 50',
            prefixIcon: Icon(Icons.shopping_cart),
            suffixText: '₺',
            helperText: 'Bu tutarın altında sipariş kabul edilmez',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildPaymentInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ödeme Takvimi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          initialValue: _paymentCycle,
          decoration: const InputDecoration(
            labelText: 'Ödeme Döngüsü',
            prefixIcon: Icon(Icons.calendar_today),
          ),
          items: const [
            DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
            DropdownMenuItem(value: 'biweekly', child: Text('İki Haftada Bir')),
            DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
          ],
          onChanged: (value) => setState(() => _paymentCycle = value!),
        ),

        const SizedBox(height: 16),

        if (_paymentCycle == 'weekly' || _paymentCycle == 'biweekly') ...[
          const Text('Ödeme Günü:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']
                .asMap()
                .entries
                .map((entry) {
              final day = entry.key + 1;
              final label = entry.value;
              return ChoiceChip(
                label: Text(label),
                selected: _paymentDay == day,
                onSelected: (selected) {
                  if (selected) setState(() => _paymentDay = day);
                },
              );
            }).toList(),
          ),
        ] else if (_paymentCycle == 'monthly') ...[
          const Text('Ayın Kaçında Ödeme Alacaksınız?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(28, (index) {
              final day = index + 1;
              return ChoiceChip(
                label: Text('$day'),
                selected: _paymentDay == day,
                onSelected: (selected) {
                  if (selected) setState(() => _paymentDay = day);
                },
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildTaxBankStep() {
    return Column(
      children: [
        const Text(
          'Vergi Bilgileri',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _taxNumberController,
          decoration: const InputDecoration(
            labelText: 'Vergi Numarası',
            prefixIcon: Icon(Icons.assignment),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tradeRegistryController,
          decoration: const InputDecoration(
            labelText: 'Ticaret Sicil No (Opsiyonel)',
            prefixIcon: Icon(Icons.business_center),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Banka Bilgileri',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bankNameController,
          decoration: const InputDecoration(
            labelText: 'Banka Adı',
            prefixIcon: Icon(Icons.account_balance),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ibanController,
          decoration: const InputDecoration(
            labelText: 'IBAN',
            prefixIcon: Icon(Icons.credit_card),
            hintText: 'TR...',
          ),
          validator: (v) =>
              (v?.isEmpty ?? true) || !v!.startsWith('TR') ? 'Geçerli IBAN' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _accountHolderController,
          decoration: const InputDecoration(
            labelText: 'Hesap Sahibi',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
      ],
    );
  }

  void _onStepContinue() async {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      // Son adım - Kayıt yap
      await _submitRegistration();
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? userId;

    try {
      print('🚀 Kayıt işlemi başlıyor...');
      
      // 1. Supabase Auth ile hesap oluştur
      print('📧 Auth ile hesap oluşturuluyor: ${_emailController.text}');
      final response = await SupabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw Exception('Auth kaydı başarısız - kullanıcı oluşturulamadı');
      }

      userId = response.user!.id;
      final now = DateTime.now().toIso8601String();

      print('🔑 Auth başarılı - User ID: $userId');
      print('💾 Users tablosuna kaydediliyor...');

      // 2. Supabase'e işletme bilgilerini kaydet
      // NOT: id'yi auth.users tablosundan alıp manuel set ediyoruz
      // UPSERT kullanıyoruz çünkü id zaten Auth'da oluşmuş olabilir
      final insertResult = await SupabaseService.from('users').upsert({
        'id': userId, // Auth'tan gelen UUID
        // Temel Bilgiler
        'role': 'merchant', // ✅ SABIT: Hepsi merchant
        // NOT: business_type kolonu users tablosunda yok - commission_settings içinde tutuyoruz
        'business_name': _businessNameController.text.trim(),
        'owner_name': _ownerNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),

        // Adres
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'delivery_radius': double.tryParse(_deliveryRadiusController.text) ?? 5.0,
        
        // 📍 İşletme adres bilgileri (business_* kolonları)
        'business_address': _addressController.text.trim(),
        'business_phone': _phoneController.text.trim(),
        
        // 🗺️ Konum koordinatları (JSON formatında)
        // current_location: Anlık GPS konumu (ileride güncellenebilir)
        // business_location: İşletmenin SABİT konumu (harita ile seçilen - kurye çağırırken kullanılır)
        'current_location': _selectedLatitude != null && _selectedLongitude != null
            ? {
                'latitude': _selectedLatitude,
                'longitude': _selectedLongitude,
              }
            : null,
        
        // ✅ YENİ: İşletme SABİT konumu (kurye çağırırken kullanılır)
        'business_location': _selectedLatitude != null && _selectedLongitude != null
            ? {
                'latitude': _selectedLatitude,
                'longitude': _selectedLongitude,
                'address': _addressController.text.trim(), // İşletme adresi de ekle
              }
            : null,

        // Komisyon Ayarları (JSONB)
        'commission_settings': {
          'type': _commissionType,
          'business_type': _businessType, // İşletme türü: 'restaurant', 'market', 'cafe', vb.
          'commission_rate': _commissionType == 'percentage'
              ? double.tryParse(_commissionRateController.text)
              : null,
          'per_order_fee': _commissionType == 'perOrder'
              ? double.tryParse(_perOrderFeeController.text)
              : null,
          'minimum_order': double.tryParse(_minimumOrderController.text) ?? 0.0,
        },

        // Ödeme Bilgileri (JSONB)
        'payment_settings': {
          'payment_cycle': _paymentCycle,
          'payment_day': _paymentDay,
          'bank_info': {
            'bank_name': _bankNameController.text.trim(),
            'iban': _ibanController.text.trim(),
            'account_holder': _accountHolderController.text.trim(),
          },
        },

        // Vergi Bilgileri (JSONB)
        'tax_info': {
          'tax_number': _taxNumberController.text.trim(),
          'trade_registry': _tradeRegistryController.text.trim(),
        },

        // Durum
        'is_active': false, // Admin onayı bekliyor
        'status': 'pending',
        'created_at': now,
        'updated_at': now,
      }).select();

      if (insertResult.isEmpty) {
        throw Exception('Users tablosuna kayıt başarısız - veri eklenemedi');
      }

      print('✅ Users tablosuna kayıt başarılı!');
      print('📊 Kayıt verisi: $insertResult');

      setState(() => _isLoading = false);

      // Başarı mesajı
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('✅ Başvuru Alındı'),
          content: const Text(
            'Başvurunuz başarıyla alındı!\n\n'
            'Firma yöneticisi başvurunuzu inceleyecek ve '
            'komisyon bilgilerinizi doğrulayacaktır.\n\n'
            'Onay sonrası e-posta ile bilgilendirileceksiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Kayıt ekranını kapat
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ HATA: $e');
      
      setState(() => _isLoading = false);
      
      // Eğer Auth'da hesap oluştuysa ama users'a eklenemediysе temizle
      if (userId != null) {
        print('🧹 Auth\'dan yarım kalmış kaydı temizliyorum...');
        try {
          // Auth'dan kullanıcıyı sil
          await SupabaseService.client.auth.admin.deleteUser(userId);
          print('✅ Yarım kalmış kayıt temizlendi');
        } catch (deleteError) {
          print('⚠️ Temizleme hatası: $deleteError');
          print('💡 Supabase Dashboard > Authentication\'dan manuel silin: ${_emailController.text}');
        }
      }
      
      if (!mounted) return;
      
      // Kullanıcıya anlaşılır hata mesajı göster
      String errorMessage = 'Kayıt sırasında bir hata oluştu';
      
      if (e.toString().contains('already registered') || 
          e.toString().contains('user_already_exists') ||
          e.toString().contains('23505')) { // Unique constraint violation
        errorMessage = '❌ Bu e-posta zaten kayıtlı!\n\n'
            'Eğer kaydınızı tamamlayamadıysanız, '
            'lütfen farklı bir e-posta adresi kullanın veya '
            'destek ekibiyle iletişime geçin.';
      } else if (e.toString().contains('Invalid') || e.toString().contains('validation')) {
        errorMessage = '⚠️ Girdiğiniz bilgilerde hata var\n\n'
            'Lütfen tüm alanları doğru doldurduğunuzdan emin olun.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _buildCommissionExample() {
    final rate = double.tryParse(_commissionRateController.text);
    if (rate == null) return 'Komisyon oranı girin';
    
    const exampleOrder = 100.0;
    final commission = exampleOrder * (rate / 100);
    final yourEarning = exampleOrder - commission;
    
    return 'Örnek: ${exampleOrder.toStringAsFixed(0)}₺ siparişte '
        '${yourEarning.toStringAsFixed(2)}₺ size, '
        '${commission.toStringAsFixed(2)}₺ platform komisyonu';
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    _commissionRateController.dispose();
    _perOrderFeeController.dispose();
    _minimumOrderController.dispose();
    _deliveryRadiusController.dispose();
    _bankNameController.dispose();
    _ibanController.dispose();
    _accountHolderController.dispose();
    _taxNumberController.dispose();
    _tradeRegistryController.dispose();
    super.dispose();
  }
}
