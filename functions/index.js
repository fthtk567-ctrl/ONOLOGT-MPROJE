const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * YENİ TESLİMAT TALEBİ OLUŞTUĞUNDA KURYEYE BİLDİRİM GÖNDER
 * Firestore trigger: deliveryRequests collection'a yeni doküman eklenince
 */
exports.sendDeliveryNotificationToCourier = functions.firestore
  .document('deliveryRequests/{deliveryId}')
  .onCreate(async (snap, context) => {
    try {
      const deliveryData = snap.data();
      const deliveryId = context.params.deliveryId;

      console.log('🚀 Yeni teslimat talebi oluşturuldu:', deliveryId);
      console.log('📦 Delivery Data:', deliveryData);

      // Tüm kuryelerin FCM tokenlarını al
      const couriersSnapshot = await admin.firestore()
        .collection('users')
        .where('role', '==', 'courier')
        .where('isActive', '==', true)
        .get();

      if (couriersSnapshot.empty) {
        console.log('❌ Aktif kurye bulunamadı!');
        return null;
      }

      console.log(`✅ ${couriersSnapshot.size} aktif kurye bulundu`);

      // Her kuryeye bildirim gönder
      const promises = [];
      
      couriersSnapshot.forEach(courierDoc => {
        const courierData = courierDoc.data();
        const fcmToken = courierData.fcmToken;

        if (!fcmToken) {
          console.log(`⚠️ Kurye ${courierDoc.id} için FCM token yok`);
          return;
        }

        // Bildirim mesajını hazırla
        const message = {
          token: fcmToken,
          notification: {
            title: '🚚 Yeni Teslimat Talebi!',
            body: `${deliveryData.merchantName || 'Bir restoran'} teslimat bekliyor - ${deliveryData.packageCount || 1} paket`
          },
          data: {
            deliveryId: deliveryId,
            merchantId: deliveryData.merchantId || '',
            merchantName: deliveryData.merchantName || '',
            packageCount: String(deliveryData.packageCount || 1),
            declaredAmount: String(deliveryData.declaredAmount || 0),
            type: 'new_delivery',
            click_action: 'FLUTTER_NOTIFICATION_CLICK'
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'new_order_channel',
              priority: 'max',
              defaultSound: true,
              defaultVibrateTimings: true
            }
          }
        };

        console.log(`📤 Bildirim gönderiliyor: ${courierData.name || courierDoc.id}`);
        
        promises.push(
          admin.messaging().send(message)
            .then(response => {
              console.log(`✅ Bildirim gönderildi: ${courierData.name || courierDoc.id} - ${response}`);
              return response;
            })
            .catch(error => {
              console.error(`❌ Bildirim gönderilemedi: ${courierData.name || courierDoc.id}`, error);
              return null;
            })
        );
      });

      await Promise.all(promises);
      console.log('🎉 Tüm bildirimler gönderildi!');
      
      return null;
    } catch (error) {
      console.error('❌ HATA:', error);
      return null;
    }
  });

/**
 * TESLİMAT DURUMU DEĞİŞTİĞİNDE BİLDİRİM GÖNDER
 */
exports.sendDeliveryStatusUpdate = functions.firestore
  .document('deliveryRequests/{deliveryId}')
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const deliveryId = context.params.deliveryId;

      // Durum değişmediyse çık
      if (beforeData.status === afterData.status) {
        return null;
      }

      console.log(`📊 Teslimat durumu değişti: ${beforeData.status} -> ${afterData.status}`);

      // Merchant'a bildirim gönder
      if (afterData.merchantId) {
        const merchantDoc = await admin.firestore()
          .collection('users')
          .doc(afterData.merchantId)
          .get();

        if (merchantDoc.exists && merchantDoc.data().fcmToken) {
          const statusMessages = {
            'accepted': '✅ Kurye teslimatı kabul etti',
            'picked_up': '📦 Paket alındı, yolda',
            'delivered': '🎉 Teslimat tamamlandı',
            'cancelled': '❌ Teslimat iptal edildi'
          };

          const message = {
            token: merchantDoc.data().fcmToken,
            notification: {
              title: 'Teslimat Durumu',
              body: statusMessages[afterData.status] || 'Durum güncellendi'
            },
            data: {
              deliveryId: deliveryId,
              status: afterData.status,
              type: 'status_update'
            }
          };

          await admin.messaging().send(message);
          console.log('✅ Merchant\'a durum bildirimi gönderildi');
        }
      }

      return null;
    } catch (error) {
      console.error('❌ HATA:', error);
      return null;
    }
  });
