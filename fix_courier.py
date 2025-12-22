import requests
import json

# Supabase bilgileri
SUPABASE_URL = "https://oilldfyywtzybrmpyixx.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NzI4MjksImV4cCI6MjA3NjI0ODgyOX0.kwTQgWja1VJBNA4sXEbznmv9LMoyO_5rioaTaQXvKsM"

headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

print("🚀 Courier kullanıcısını müsait yapıyorum...")
print("")

# 1. Courier kullanıcısını bul
print("🔍 courier@onlog.com aranıyor...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/users?email=eq.courier@onlog.com&role=eq.courier&select=*",
    headers=headers
)

if response.status_code != 200:
    print(f"❌ HATA! Status: {response.status_code}")
    print(response.text)
    exit(1)

users = response.json()
if not users:
    print("❌ Kullanıcı bulunamadı!")
    exit(1)

user = users[0]
user_id = user['id']
owner_name = user.get('owner_name', 'N/A')
current_available = user.get('is_available', False)

print(f"✅ Kullanıcı bulundu!")
print(f"   ID: {user_id}")
print(f"   İsim: {owner_name}")
print(f"   Şu anki durum: {'MÜSAİT ✅' if current_available else 'MÜSAİT DEĞİL ❌'}")
print("")

# 2. is_available = true yap
print("🔧 is_available = TRUE yapılıyor...")
update_response = requests.patch(
    f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
    headers=headers,
    json={"is_available": True}
)

if update_response.status_code not in [200, 204]:
    print(f"❌ GÜNCELLEME HATASI! Status: {update_response.status_code}")
    print(update_response.text)
    exit(1)

print("✅ BAŞARILI! Güncelleme yapıldı!")
print("")

# 3. Kontrol et
print("🔍 Kontrol ediliyor...")
check_response = requests.get(
    f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}&select=is_available",
    headers=headers
)

if check_response.status_code == 200:
    check_data = check_response.json()
    if check_data:
        new_status = check_data[0].get('is_available', False)
        print(f"   Yeni durum: {'MÜSAİT ✅' if new_status else 'MÜSAİT DEĞİL ❌'}")
        
        if new_status:
            print("")
            print("=" * 60)
            print("🎉 SORUN ÇÖZÜLDÜ!")
            print("=" * 60)
            print("")
            print("✅ Courier artık müsait!")
            print("✅ Merchant panel şimdi kurye bulabilir!")
            print("")
            print("Merchant panel'den kurye çağır testi yap!")
        else:
            print("❌ Hala FALSE!")
    else:
        print("❌ Kontrol verisi gelmedi!")
else:
    print(f"❌ KONTROL HATASI! Status: {check_response.status_code}")
