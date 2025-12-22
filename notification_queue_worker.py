#!/usr/bin/env python3
"""
ONLOG - Direct FCM Notification Sender
Web CORS bypass için doğrudan FCM gönderen script
"""
import json
import sys

try:
    from google.oauth2 import service_account
    import google.auth.transport.requests
    import requests
except ImportError:
    print("❌ Gerekli paketler yok!")
    print("Yüklemek için: pip install google-auth requests")
    sys.exit(1)

# Firebase Service Account
SERVICE_ACCOUNT_FILE = r"c:\Users\PC\Downloads\onlog-push-firebase-adminsdk-fbsvc-787041d780.json"

def get_access_token():
    """Firebase OAuth2 access token al"""
    try:
        credentials = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE,
            scopes=['https://www.googleapis.com/auth/firebase.messaging']
        )
        request = google.auth.transport.requests.Request()
        credentials.refresh(request)
        print(f"✅ OAuth2 token alındı")
        return credentials.token
    except Exception as e:
        print(f"❌ Token hatası: {e}")
        return None

def send_fcm(token, title, body, data=None):
    """FCM V1 API ile bildirim gönder"""
    try:
        access_token = get_access_token()
        if not access_token:
            return False
        
        message = {
            "message": {
                "token": token,
                "notification": {
                    "title": title,
                    "body": body
                },
                "android": {
                    "priority": "high",
                    "notification": {
                        "channel_id": "new_order",
                        "sound": "default"
                    }
                },
                "data": data or {}
            }
        }
        
        url = 'https://fcm.googleapis.com/v1/projects/onlog-push/messages:send'
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }
        
        print(f"📤 FCM'e gönderiliyor...")
        response = requests.post(url, headers=headers, json=message, timeout=10)
        
        if response.status_code == 200:
            print(f"✅ Bildirim başarıyla gönderildi!")
            print(f"📥 Response: {response.json()}")
            return True
        else:
            print(f"❌ FCM hatası: {response.status_code}")
            print(f"📄 Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Hata: {e}")
        return False

if __name__ == "__main__":
    print("🚀 ONLOG - FCM Notification Test")
    print("=" * 50)
    
    # Kurye FCM token
    token = "cB5SRyA1QuOc4bBOfpxfJe:APA91bFg3hRXvTHLEzDiC0xJ8Mq7EZOPrN2XQjGk9sVwYtUmIbAcDeFhJkLmNoPqRsTuVwXyZ0AbCdEfGhIjKlMnOpQrStUvWxYz1A2bC3dE4fG5hI6jK7lM8nO9pQ0rS1tU2vW3xY4z"
    
    success = send_fcm(
        token=token,
        title="🚀 Yeni Teslimat İsteği!",
        body="Restoran - test2 - 1 paket - 1.00 TL",
        data={
            "type": "new_delivery_request",
            "test": "true",
            "from": "Python Script"
        }
    )
    
    print("=" * 50)
    if success:
        print("✅ TEST BAŞARILI - Kurye telefonunu kontrol et!")
    else:
        print("❌ TEST BAŞARISIZ - Loglara bak")
