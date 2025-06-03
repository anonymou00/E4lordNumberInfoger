#!/bin/bash

# Renk tanımları
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Giriş mesajı
echo -e "${YELLOW}📲 E4NumInfo başlatılıyor..."

# Python kontrolü
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3 yüklü değil."
    exit 1
fi

# venv modülü kontrolü
if ! python3 -m venv --help &> /dev/null; then
    echo -e "${RED}❌ 'venv' modülü eksik. 'python3-venv' yüklemelisin."
    exit 1
fi

# Sanal ortam oluşturma
if [ ! -d "env" ]; then
    echo -e "${YELLOW}🧪 Sanal ortam oluşturuluyor..."
    python3 -m venv env || { echo -e "${RED}❌ Ortam oluşturulamadı."; exit 1; }
fi

# Ortamı aktif etme
source env/bin/activate || { echo -e "${RED}❌ Ortam aktifleştirilemedi."; exit 1; }

# pip güncelleme
echo -e "${YELLOW}⬆️ pip güncelleniyor..."
pip install --upgrade pip > /dev/null 2>&1

# Gerekli modülleri yükleme
echo -e "${YELLOW}📦 Gerekli modüller kuruluyor..."
pip install phonenumbers colorama > /dev/null 2>&1

# PhoneInfoga indir ve binary olarak ayarla
if [ ! -f "PhoneInfoga/phoneinfoga" ]; then
    echo -e "${YELLOW}⬇️ PhoneInfoga indiriliyor (binary)..."
    mkdir -p PhoneInfoga
    cd PhoneInfoga
    wget https://github.com/sundowndev/phoneinfoga/releases/latest/download/phoneinfoga_linux_amd64 -O phoneinfoga
    chmod +x phoneinfoga
    cd ..
fi

# Python betiğini oluştur
cat << 'EOF' > e4numinfo.py
#!/usr/bin/env python3

import phonenumbers
from phonenumbers import geocoder, carrier, timezone, number_type, PhoneNumberFormat
from colorama import Fore, init
import sys

init(autoreset=True)

languages = {
    "1": ("Azerbaijani", "Azərbaycan dili"),
    "2": ("Turkish", "Türkçe"),
    "3": ("English", "English"),
    "4": ("Chinese", "中文"),
    "5": ("Arabic", "العربية"),
    "6": ("Hindi", "हिंदी"),
    "7": ("Urdu", "اردو"),
    "8": ("German", "Deutsch"),
    "9": ("French", "Français"),
    "10": ("Portuguese", "Português")
}

translations = {
    "prompt": {
        "Azerbaijani": "Telefon nömrəsini daxil edin (+ölkə kodu ilə): ",
        "Turkish": "Telefon numarasını girin (+ülke kodu ile): ",
        "English": "Enter phone number (with +country code): ",
        "Chinese": "请输入电话号码（含国家代码）: ",
        "Arabic": "أدخل رقم الهاتف (مع رمز الدولة): ",
        "Hindi": "फ़ोन नंबर दर्ज करें (+देश कोड के साथ): ",
        "Urdu": "فون نمبر درج کریں (+ملک کوڈ کے ساتھ): ",
        "German": "Geben Sie die Telefonnummer ein (+Ländervorwahl): ",
        "French": "Entrez le numéro de téléphone (+code pays): ",
        "Portuguese": "Digite o número de telefone (com código do país): "
    },
    "invalid": {
        "Azerbaijani": "Yanlış telefon nömrəsi.",
        "Turkish": "Geçersiz telefon numarası.",
        "English": "Invalid phone number.",
        "Chinese": "无效的电话号码。",
        "Arabic": "رقم هاتف غير صالح.",
        "Hindi": "अमान्य फ़ोन नंबर।",
        "Urdu": "غیر درست فون نمبر۔",
        "German": "Ungültige Telefonnummer.",
        "French": "Numéro de téléphone invalide.",
        "Portuguese": "Número de telefone inválido."
    },
    "result": {
        "Azerbaijani": "Telefon haqqında məlumat:",
        "Turkish": "Telefon Bilgileri:",
        "English": "Phone Information:",
        "Chinese": "电话号码信息：",
        "Arabic": "معلومات رقم الهاتف:",
        "Hindi": "फ़ोन जानकारी:",
        "Urdu": "فون کی معلومات:",
        "German": "Telefoninformationen:",
        "French": "Informations du téléphone:",
        "Portuguese": "Informações do telefone:"
    }
}

print(Fore.CYAN + "Dilinizi seçin / Select your language:")
for key in languages:
    print(f"{key}. {languages[key][1]}")

lang_choice = input(Fore.YELLOW + "\nSeçim / Choice: ").strip()
lang = languages.get(lang_choice, ("English",))[0]

number_input = input(Fore.YELLOW + translations["prompt"][lang])

try:
    number_obj = phonenumbers.parse(number_input)
    if not phonenumbers.is_valid_number(number_obj):
        print(Fore.RED + translations["invalid"][lang])
        sys.exit(1)

    print(Fore.GREEN + f"\n{translations['result'][lang]}")
    print(Fore.CYAN + f"✅ Geçerli / Valid: {phonenumbers.is_valid_number(number_obj)}")
    print(Fore.CYAN + f"📞 Tür / Type: {number_type(number_obj)}")
    print(Fore.CYAN + f"🌍 Ülke / Country: {geocoder.description_for_number(number_obj, lang)}")
    print(Fore.CYAN + f"📡 Operatör / Carrier: {carrier.name_for_number(number_obj, lang)}")
    print(Fore.CYAN + f"🕓 Zaman Dilimi / Timezone: {timezone.time_zones_for_number(number_obj)}")
    print(Fore.CYAN + f"🌐 Uluslararası Format: {phonenumbers.format_number(number_obj, PhoneNumberFormat.INTERNATIONAL)}")

    with open("number.tmp", "w") as f:
        f.write(number_input)

except Exception as e:
    print(Fore.RED + f"Hata / Error: {str(e)}")
    sys.exit(1)
EOF

# Python betiğini çalıştır
echo -e "${GREEN}🚀 Bilgiler toplanıyor...\n"
python3 e4numinfo.py

# PhoneInfoga çalıştır
if [ -f "number.tmp" ]; then
    NUM=$(cat number.tmp)
    echo -e "${YELLOW}🔍 Ek bilgi için PhoneInfoga çalıştırılıyor..."
    ./PhoneInfoga/phoneinfoga scan -n "$NUM"
    rm number.tmp
fi

# Ortamdan çık
deactivate
