#!/bin/bash

# Detect environment
ENVIRONMENT=""
if [[ "$OSTYPE" == "linux-android"* ]]; then
    ENVIRONMENT="termux"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    ENVIRONMENT="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    ENVIRONMENT="macos"
else
    ENVIRONMENT="unknown"
    exit 1
fi

echo "################################"
echo "# Membangun di : $ENVIRONMENT" #
echo "################################"
sleep 3

# --- Konfigurasi Proyek Baru ---
DEFAULT_PROJECT_NAME="my_project" # Nama default jika tidak diinput
DEFAULT_LARAVEL_VERSION="^12.0"       # Versi Laravel default (untuk PHP)

# Meminta input nama proyek
read -p "Masukkan nama proyek Laravel baru, (default: $DEFAULT_PROJECT_NAME): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_PROJECT_NAME} # Gunakan default jika kosong

# Meminta input versi Laravel
read -p "Masukkan versi Laravel (default: $DEFAULT_LARAVEL_VERSION): " LARAVEL_VERSION
LARAVEL_VERSION=${LARAVEL_VERSION:-$DEFAULT_LARAVEL_VERSION} # Gunakan default jika kosong

echo "🚀 Memulai proses pembuatan dan inisialisasi proyek Laravel baru: '$PROJECT_NAME' (v$LARAVEL_VERSION)..."

# 1. Cek Dependensi Sistem
echo -e "\n--- Memeriksa dependensi sistem ---"
if ! command -v composer &> /dev/null
then
    echo "❌ Composer tidak ditemukan. Silakan instal Composer terlebih dahulu."
    echo "   Panduan: https://getcomposer.org/download/"
    exit 1
fi
if ! command -v npm &> /dev/null
then
    echo "❌ NPM (Node.js) tidak ditemukan. Silakan instal Node.js dan NPM terlebih dahulu."
    echo "   Panduan: https://nodejs.org/en/download/"
    exit 1
fi
echo "✅ Composer dan NPM terdeteksi."

# 2. Mengunduh Kerangka Laravel
echo -e "\n--- Mengunduh kerangka Laravel '$PROJECT_NAME' ---"
if [ -d "$PROJECT_NAME" ]; then
    echo "⚠️ Folder '$PROJECT_NAME' sudah ada. Melewati pembuatan proyek baru."
    echo "   Jika Anda ingin menginisialisasi proyek yang sudah ada, gunakan skrip 'init_exist.sh'."
    exit 1
else
    composer create-project "laravel/laravel:$LARAVEL_VERSION" "$PROJECT_NAME" --no-interaction --prefer-dist
    if [ $? -ne 0 ]; then
        echo "❌ Gagal mengunduh kerangka Laravel. Silakan periksa pesan error di atas."
        exit 1
    fi
    echo "✅ Kerangka Laravel berhasil diunduh ke folder '$PROJECT_NAME'."
fi

# Masuk ke direktori proyek yang baru diunduh
cd "$PROJECT_NAME" || { echo "❌ Gagal masuk ke direktori proyek '$PROJECT_NAME'."; exit 1; }

# --- Langkah-langkah Inisialisasi Proyek ---

# 3. Instalasi Dependensi PHP (seharusnya sudah dilakukan oleh create-project, ini untuk memastikan)
echo -e "\n--- Memastikan dependensi PHP terinstal ---"
composer install --no-interaction --prefer-dist
if [ $? -ne 0 ]; then
    echo "❌ Gagal memastikan dependensi Composer. Silakan periksa pesan error di atas."
    exit 1
fi
echo "✅ Dependensi PHP siap."

# 4. Instalasi Dependensi JavaScript (via NPM)
echo -e "\n--- Menginstal dependensi JavaScript (NPM) ---"
npm install
if [ $? -ne 0 ]; then
    echo "❌ Gagal menginstal dependensi NPM. Silakan periksa pesan error di atas."
    exit 1
fi
echo "✅ Dependensi JavaScript berhasil diinstal."

# 5. Menyiapkan File .env (jika belum ada)
echo -e "\n--- Menyiapkan file .env ---"
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ File .env berhasil dibuat dari .env.example."
else
    echo "ℹ️ File .env sudah ada. Melewati pembuatan file .env baru."
fi

# 6. Membuat Kunci Aplikasi (Application Key)
echo -e "\n--- Membuat kunci aplikasi ---"
if grep -q "APP_KEY=" .env && ! grep -q "APP_KEY=$" .env; then
    echo "ℹ️ APP_KEY sudah ada di .env. Melewati pembuatan kunci baru."
    echo "Jika ingin mengganti APP_KEY, lakukan secara manual 'php artisan key:generate'"
else
    php artisan key:generate
    echo "✅ Kunci aplikasi berhasil dibuat."
fi

# 7. Membuat Link Simbolik Storage
echo -e "\n--- Membuat symbolic link untuk storage ---"
read -p "Apakah Anda ingin membuat symbolic link untuk storage? (y/n): " -n 1 -r SYMBOLIC
echo
if [[ $SYMBOLIC =~ ^[Yy]$ ]]
then
    php artisan storage:link
    echo "✅ Symbolic link storage berhasil dibuat."
else
    echo "ℹ️ Symbolic link untuk storage dilewati. Silahkan jalankan 'php artisan storage:link' secara manual nanti."
fi

# 8. Menjalankan Migrasi Database
echo -e "\n--- Menjalankan migrasi database ---"
read -p "Apakah Anda ingin menjalankan migrasi database sekarang? (y/n): " -n 1 -r REPLY
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    php artisan migrate
    echo "✅ Migrasi database selesai."
    read -p "Apakah Anda ingin menjalankan database seeder (db:seed) sekarang? (y/n): " -n 1 -r SEED_REPLY
    echo
    if [[ $SEED_REPLY =~ ^[Yy]$ ]]
    then
        php artisan db:seed
        echo "✅ Database seeder selesai."
    fi
else
    echo "ℹ️ Migrasi database dilewati. Silakan jalankan 'php artisan migrate' secara manual nanti."
fi

# 9. Kompilasi Aset Frontend (untuk pengembangan) - Disarankan di PC/Laptop
echo -e "\n--- Mengkompilasi aset frontend (menggunakan Vite) ---"
echo "⚠️ PERHATIAN: Proses 'npm run dev' atau 'npm run build' (Vite) sangat memakan sumber daya."
echo "   Ini mungkin sangat lambat atau gagal di Termux, tergantung spesifikasi perangkat Anda."
echo "   Disarankan untuk mengkompilasi aset di PC/laptop dan menyalin folder 'public/build' ke sini."

read -p "Apakah Anda menggunakan Termux untuk menjalankan proyek ini? (y/n)" -n 1 -r BUILD_TERMUX
echo
if [[ $BUILD_TERMUX =~ ^[Yy]$ ]]
then
    LARAVEL_FULL_VERSION=$(php artisan --version 2>&1)
    LARAVEL_MAJOR_VERSION=$(echo "$LARAVEL_FULL_VERSION" | grep -oP '(?<=Laravel Framework |Laravel\s)\d+' | head -n 1)

    if ! [[ "$LARAVEL_MAJOR_VERSION" =~ ^[0-9]+$ ]]; then
        echo "Gagal mendapatkan versi utama Laravel atau format tidak valid: '$LARAVEL_FULL_VERSION'"
        echo "Pastikan Anda menjalankan script di dalam direktori project Laravel dan 'php artisan --version' berfungsi."
        exit 1 # Keluar dari script karena versi tidak valid
    fi

    LARAVEL_MAJOR_VERSION_INT=${LARAVEL_MAJOR_VERSION%.*}

    if [ "$LARAVEL_MAJOR_VERSION_INT" -eq 12 ]; then
        npm install lightningcss.android-arm64.node --save-optional # depedensi optional untuk termux android-arm64
        npm run build
        echo "✅ Kompilasi aset frontend selesai."
    elif [ "$LARAVEL_MAJOR_VERSION_INT" -lt 12 ]; then
        echo "Versi Laravel di bawah 12 ($LARAVEL_MAJOR_VERSION_INT). Mengabaikan instalasi 'lightningcss untuk Amdroid'..."
        npm run build
    else
        # echo "Versi Laravel di atas 12 ($LARAVEL_MAJOR_VERSION_INT). Mengabaikan instalasi 'lightningcss untuk Android'..."
        echo
    fi
    
else
    npm run build
    if [ $? -ne 0 ]; then
        echo "❌ Gagal mengkompilasi aset frontend. Ini normal di beberapa perangkat Termux."
        echo "   Silakan coba di PC/laptop atau salin folder 'public/build' yang sudah dikompilasi."
    else
        echo "✅ Kompilasi aset frontend selesai."
    fi
fi

read -p "Apakah Anda tetap ingin mencoba 'npm run dev' sekarang? (y/n): " -n 1 -r BUILD_REPLY
echo
if [[ $BUILD_REPLY =~ ^[Yy]$ ]]
then
    LARAVEL_FULL_VERSION=$(php artisan --version 2>&1)
    LARAVEL_MAJOR_VERSION=$(echo "$LARAVEL_FULL_VERSION" | grep -oP '(?<=Laravel Framework |Laravel\s)\d+' | head -n 1)

    if ! [[ "$LARAVEL_MAJOR_VERSION" =~ ^[0-9]+$ ]]; then
        echo "Gagal mendapatkan versi utama Laravel atau format tidak valid: '$LARAVEL_FULL_VERSION'"
        echo "Pastikan Anda menjalankan script di dalam direktori project Laravel dan 'php artisan --version' berfungsi."
        exit 1 # Keluar dari script karena versi tidak valid
    fi

    LARAVEL_MAJOR_VERSION_INT=${LARAVEL_MAJOR_VERSION%.*}
    if [ "$LARAVEL_MAJOR_VERSION_INT" -eq 12 ]; then
        composer run dev # untuk Laravel Versi 12
        if [ $? -ne 0 ]; then
            echo "❌ Gagal mengkompilasi aset frontend. Ini normal di beberapa perangkat Termux."
            echo "   Silakan coba di PC/laptop atau salin folder 'public/build' yang sudah dikompilasi."
        else
            echo "✅ Kompilasi aset frontend selesai."
        fi
    elif [ "$LARAVEL_MAJOR_VERSION_INT" -lt 12 ]; then
        npm run dev # Atau npm run build, sesuaikan dengan package.json Anda
        if [ $? -ne 0 ]; then
            echo "❌ Gagal mengkompilasi aset frontend. Ini normal di beberapa perangkat Termux."
            echo "   Silakan coba di PC/laptop atau salin folder 'public/build' yang sudah dikompilasi."
        else
            echo "✅ Kompilasi aset frontend selesai."
        fi
    else
        echo
    fi
else
    echo "ℹ️ Kompilasi aset frontend dilewati. Silakan kompilasi secara manual atau salin dari tempat lain."
fi

# 10. Pembersihan Cache
echo -e "\n--- Membersihkan cache Laravel ---"
php artisan optimize:clear
echo "✅ Cache Laravel dibersihkan."

echo -e "\n-----------------------------------------------------"
echo "🎉 Proyek Laravel '$PROJECT_NAME' berhasil diinisialisasi!"
echo "Untuk ke proyek Anda, jalankan perintah 'cd $PROJECT_NAM'"
echo "Kemudian: "
echo "➡️ Konfigurasi file .env Anda (jika belum). Contoh: Database Credentials"
echo "➡️ Jalankan 'php artisan serve' untuk memulai server lokal."
echo "➡️ Akses proyek Anda di browser (biasanya http://127.0.0.1:8000)."
echo "-----------------------------------------------------"
