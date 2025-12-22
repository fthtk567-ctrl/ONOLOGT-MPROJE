import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:onlog_shared/onlog_shared.dart';

class ExcelService {
  static Future<String?> exportOrdersToExcel(
    List<Order> orders,
    String platformName,
  ) async {
    try {
      // İzin kontrolü
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return null;
      }

      // Excel dosyası oluştur
      var excel = Excel.createExcel();
      
      // Varsayılan sheet'i sil ve yeni sheet ekle
      excel.delete('Sheet1');
      Sheet sheet = excel['Siparişler'];

      // Başlık satırı
      List<String> headers = [
        'Sipariş No',
        'Platform',
        'Müşteri Adı',
        'Telefon',
        'Adres',
        'İl/İlçe',
        'Ürünler',
        'Toplam Tutar',
        'Durum',
        'Sipariş Zamanı',
        'Not',
      ];

      // Başlıkları yaz
      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.green300,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // Veri satırlarını yaz
      for (int i = 0; i < orders.length; i++) {
        Order order = orders[i];
        int rowIndex = i + 1;

        // Sipariş No
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(order.id);

        // Platform
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(_getPlatformName(order.platform));

        // Müşteri Adı
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(order.customer.name);

        // Telefon
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(order.customer.phone);

        // Adres
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(order.customer.address.fullAddress);

        // İl/İlçe
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = TextCellValue('${order.customer.address.district}/${order.customer.address.city}');

        // Ürünler
        String itemsText = order.items
            .map((item) => '${item.name} x${item.quantity} (${item.price.toStringAsFixed(2)}₺)')
            .join(', ');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = TextCellValue(itemsText);

        // Toplam Tutar
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
            .value = DoubleCellValue(order.totalAmount);

        // Durum
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
            .value = TextCellValue(_getStatusName(order.status));

        // Sipariş Zamanı
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
            .value = TextCellValue(_formatDateTime(order.orderTime));

        // Not
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
            .value = TextCellValue(order.specialNote ?? '');
      }

      // Sütun genişliklerini ayarla
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      // Dosya adı oluştur
      String fileName = '${platformName}_siparisler_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}.xlsx';

      // Dosyayı kaydet
      String? filePath = await _saveExcelFile(excel, fileName);
      
      return filePath;
    } catch (e) {
      debugPrint('Excel export error: $e');
      return null;
    }
  }

  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ için yeni izin sistemi
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      
      // Eski Android sürümleri için
      if (!status.isGranted) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        return storageStatus.isGranted;
      }
      
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS için photo library izni (dosya kaydetmek için)
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }
      return status.isGranted;
    }
    
    return true; // Desktop platformlar için
  }

  static Future<String?> _saveExcelFile(Excel excel, String fileName) async {
    try {
      List<int>? excelBytes = excel.save();

      Directory? directory;
      
      if (Platform.isAndroid) {
        // Android için Downloads klasörü
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // iOS için Documents klasörü
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Desktop için Downloads klasörü
        directory = await getDownloadsDirectory();
      }

      if (directory == null) throw Exception('Downloads klasörü bulunamadı');

      String filePath = '${directory.path}/$fileName';
      File file = File(filePath);
      
      await file.writeAsBytes(excelBytes ?? []);
      
      return filePath;
    } catch (e) {
      debugPrint('Save file error: $e');
      return null;
    }
  }

  static String _getPlatformName(OrderPlatform platform) {
    switch (platform) {
      case OrderPlatform.trendyol:
        return 'Trendyol';
      case OrderPlatform.yemeksepeti:
        return 'Yemeksepeti';
      case OrderPlatform.getir:
        return 'Getir';
      case OrderPlatform.bitaksi:
        return 'BiTaksi';
      case OrderPlatform.manuel:
        return 'Manuel';
    }
  }

  static String _getStatusName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Bekliyor';
      case OrderStatus.assigned:
        return 'Kurye Atandı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.ready:
        return 'Hazır';
      case OrderStatus.pickedUp:
        return 'Kurye Aldı';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.'
        '${dateTime.month.toString().padLeft(2, '0')}.'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> openFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      debugPrint('Open file error: $e');
    }
  }
}




