# DolphinDesk — راهنمای ساخت و خروجی Windows

**نسخه راهنما:** 2026-11-08  
**محیط:** Windows / PowerShell / Visual Studio 2022 Enterprise / Flutter 3.24.5 / Rust 1.75.0  
**مخزن:** `F:\khalafi\2026_projects\DolphinDesk`  
**ابزارها:** `F:\khalafi\2026_projects\_devtools`

> **وضعیت تأییدشده:** موتور RustDesk و Flutter با موفقیت کامپایل شده و ارتباط با یک رایانه دیگر از نسخه Windows آزمایش شده است. خروجی فعلی `rustdesk.exe` است؛ تبدیل کامل نام/آیکون به DolphinDesk هنوز باید اعمال و آزمایش شود.

## 1) شروع کار در PowerShell (هر ترمینال جدید)

در PowerShell ترمینال VS Code، بلوک زیر را اجرا کنید. تنظیمات به **همان نشست ترمینال** اعمال می‌شوند:

```powershell
$project = 'F:\khalafi\2026_projects\DolphinDesk'
$tools = 'F:\khalafi\2026_projects\_devtools'
$vs = 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise'
$devcmd = "$vs\Common7\Tools\VsDevCmd.bat"

if (-not (Test-Path $devcmd)) { throw "VsDevCmd.bat not found: $devcmd" }
$lines = & cmd.exe /d /s /c "`"$devcmd`" -arch=amd64 -host_arch=amd64 >nul && set"
foreach ($line in $lines) {
    if ($line -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

$env:CARGO_HOME = "$tools\cargo"
$env:RUSTUP_HOME = "$tools\rustup"
$env:CARGO_TARGET_DIR = "$tools\cargo-target"
$env:LIBCLANG_PATH = "$tools\llvm\bin"
$env:VCPKG_ROOT = "$tools\vcpkg"
$env:PUB_CACHE = "$tools\pub-cache"
$env:Path = "$tools\cargo\bin;$tools\flutter\bin;$tools\llvm\bin;$tools\cmake\bin;$env:Path"
Set-Location $project

Write-Host "MSVC INCLUDE: $([bool]$env:INCLUDE)"
Write-Host "MSVC LIB:     $([bool]$env:LIB)"
Write-Host "Rust DLL:     $(Test-Path "$tools\cargo-target\release\librustdesk.dll")"
flutter --version
cargo --version
```

`MSVC INCLUDE` و `MSVC LIB` باید `True` باشند. وضعیت `Rust DLL` برای ساخت مجدد صرفاً Flutter باید `True` باشد.

در صورت نیاز به پراکسی V2Ray، تنظیمات آن را در همین ترمینال فعال کنید:

```powershell
$env:HTTP_PROXY  = 'http://127.0.0.1:10808'
$env:HTTPS_PROXY = 'http://127.0.0.1:10808'
$env:NO_PROXY    = 'localhost,127.0.0.1,::1'
```

## 2) ارتباط مسیر خروجی Cargo با پروژه

خروجی Rust در پوشه ابزارها ذخیره می‌شود. اگر از قبل Junction درست شده، دوباره آن را نسازید.

```powershell
$project = 'F:\khalafi\2026_projects\DolphinDesk'
$tools = 'F:\khalafi\2026_projects\_devtools'
if (-not (Test-Path "$project\target")) {
    New-Item -ItemType Junction -Path "$project\target" -Target "$tools\cargo-target"
}
Test-Path "$project\target\release\librustdesk.dll"
```

**احتیاط:** اگر `target` پوشه واقعی یا Junction موجود است، آن را حذف یا جابه‌جا نکنید. اگر فایل DLL پیدا نشد، قبل از ادامه مسیر را بررسی کنید.

## 3) ساخت سریع Windows پس از تغییرات فقط Flutter / آیکون / منابع ویندوز

در صورت تغییر فقط ظاهر Flutter یا اطلاعات/آیکون Windows و **بدون تغییر سورس Rust**، به کامپایل مجدد Cargo نیازی نیست:

```powershell
cd F:\khalafi\2026_projects\DolphinDesk\flutter
flutter pub get --offline
flutter build windows --release --no-pub
if ($LASTEXITCODE -ne 0) { throw 'Flutter build failed' }
```

اگر `pub get --offline` به‌دلیل نبودن پکیج شکست خورد، به‌جای پاک‌کردن کش، مشکل وابستگی را جداگانه بررسی کنید. اگر `pubspec.lock` یا وابستگی‌ها تغییری نکرده‌اند، می‌توانید `flutter pub get --offline` را حذف کنید.

خروجی معمول:

```text
F:\khalafi\2026_projects\DolphinDesk\flutter\build\windows\x64\runner\Release\rustdesk.exe
```

**پس از تغییر معتبر `BINARY_NAME`**، نام خروجی باید `DolphinDesk.exe` شود.

## 4) ساخت بعد از تغییر سورس Rust یا Bridge

هر تغییری در بخش Rust می‌تواند نیازمند ساخت مجدد DLL باشد. برای ساخت هماهنگ Rust + Flutter از ریشه پروژه:

```powershell
cd F:\khalafi\2026_projects\DolphinDesk
python .\build.py --portable --flutter --skip-portable-pack
if ($LASTEXITCODE -ne 0) { throw 'Full build failed' }
```

تا زمانی که ناسازگاری `hwcodec` و FFmpeg رفع نشده است از `--hwcodec` استفاده نکنید.

اگر سورس رابط `src\flutter_ffi.rs` یا تعاریف Bridge تغییر کرد، پس از تهیه نسخه پشتیبان، کدها را با Code Generator **نسخه 1.80.1** دوباره تولید کنید:

```powershell
cd F:\khalafi\2026_projects\DolphinDesk
flutter_rust_bridge_codegen --version
flutter_rust_bridge_codegen `
  --rust-input .\src\flutter_ffi.rs `
  --dart-output .\flutter\lib\generated_bridge.dart `
  --c-output .\flutter\macos\Runner\bridge_generated.h `
  --llvm-path 'F:\khalafi\2026_projects\_devtools\llvm'
```

سپس بررسی کنید:

```powershell
Test-Path .\src\bridge_generated.rs
Test-Path .\flutter\lib\generated_bridge.dart
Test-Path .\flutter\lib\generated_bridge.freezed.dart
```

**توجه:** موفق‌شدن Code Generator به‌تنهایی به‌معنای درست‌بودن همه انواع Dart نیست؛ خطاهای type در زمان Build Flutter را بررسی کنید. فایل‌های تولیدی را دستی و گروهی اصلاح نکنید.

## 5) تغییر نام و هویت برند DolphinDesk

قبل از ویرایش، تغییرات فعلی پروژه را ثبت/پشتیبان‌گیری کنید:

```powershell
cd F:\khalafi\2026_projects\DolphinDesk
git status --short
```

در `flutter\windows\CMakeLists.txt`، متغیر `BINARY_NAME` را از `rustdesk` به `DolphinDesk` تغییر دهید **اگر همین متغیر در نسخه شما وجود دارد**:

```cmake
set(BINARY_NAME "DolphinDesk")
```

در `flutter\windows\runner\Runner.rc` نام‌ها و متادیتای Windows را متناسب با برند تغییر دهید. مقادیر شناسایی‌شده در نسخه فعلی:

| فیلد | مقدار هدف پیشنهادی |
| --- | --- |
| `CompanyName` | نام قانونی شرکت منتشرکننده (پس از تعیین) |
| `FileDescription` | `DolphinDesk Remote Desktop` |
| `InternalName` | `DolphinDesk` |
| `OriginalFilename` | `DolphinDesk.exe` |
| `ProductName` | `DolphinDesk` |

آیکون فعلی به مسیر زیر اشاره دارد:

```text
flutter\windows\runner\resources\app_icon.ico
```

فایل آیکون رسمی با فرمت ICO و سایزهای چندگانه (به‌ویژه 16، 32، 48، 256) را جایگزین کنید. **از حذف فایل یا تغییر نام آن بدون به‌روزرسانی `Runner.rc` خودداری کنید.**

> تغییر نام EXE و آیکون، برندینگ کامل نیست: نام داخل UI، اعلان‌ها، نام سرویس، کلیدهای پیکربندی، نصب/حذف نصب و بروزرسانی‌ها نیز باید پیش از عرضه تجاری بازبینی شوند. نام قانونی ناشر را حدس نزنید.

## 6) ساخت نسخه قابل تحویل و تست اجرا

```powershell
$release = 'F:\khalafi\2026_projects\DolphinDesk\flutter\build\windows\x64\runner\Release'
Get-ChildItem $release | Select-Object Name, Length, LastWriteTime
$exe = Join-Path $release 'DolphinDesk.exe'
if (-not (Test-Path $exe)) { $exe = Join-Path $release 'rustdesk.exe' }
if (-not (Test-Path $exe)) { throw 'EXE not found' }
Start-Process -FilePath $exe -WorkingDirectory $release
```

**تنها فایل EXE را جداگانه به مشتری ندهید.** Flutter Windows به DLLها و پوشه `data` در کنار آن نیاز دارد. برای نسخه ZIP آزمایشی کل پوشه Release را بسته‌بندی کنید:

```powershell
$release = 'F:\khalafi\2026_projects\DolphinDesk\flutter\build\windows\x64\runner\Release'
$dest = 'F:\khalafi\2026_projects\DolphinDesk-Windows-Test.zip'
if (Test-Path $dest) { throw "Archive exists; choose a new versioned name: $dest" }
Compress-Archive -Path "$release\*" -DestinationPath $dest -CompressionLevel Optimal
Write-Host "Package: $dest"
```

این ZIP **نسخه آزمایشی پوشه Release** است، نه لزوماً Portable رسمی/Installer نهایی RustDesk. قبل از تحویل عمومی باید وضعیت وابستگی‌های Native، راه‌اندازی روی Windows تمیز، نصب سرویس و مجوزها تست شود.

## 7) تنظیم سرور اختصاصی و دامنه

- سرور فعلی: `193.186.32.178` (hbbs/hbbr؛ بدون تغییر در این مرحله)
- دامنه وب‌سایت: `dolphindesk.ir`
- نام پیشنهادی برای ID/Relay: `id.dolphindesk.ir`
- رکورد DNS پیشنهادی: `A` با Name=`id` و IP=`193.186.32.178`، در حالت DNS Only
- مقدار Key: **کلید عمومی واقعی سرور فعلی**؛ هرگز مقدار ساختگی یا کلید خصوصی را منتشر نکنید.
- ابتدا دامنه و اتصال واقعی تست شود؛ سپس تنظیمات پیش‌فرض در کلاینت و سیاست قفل‌کردن سرور اعمال شوند.

برای تست:

```powershell
Resolve-DnsName id.dolphindesk.ir -Type A
Test-NetConnection id.dolphindesk.ir -Port 21116
Test-NetConnection id.dolphindesk.ir -Port 21117
```

تست‌های بالا UDP را تأیید نمی‌کنند. مخفی‌کردن تنظیمات سرور صرفاً UI است؛ جلوگیری واقعی از تغییر مقصد ارتباطی باید در منطق پیکربندی/سیاست برنامه بررسی شود.

## 8) چک‌لیست انتشار

- [ ] آیکون رسمی DolphinDesk در فایل ICO قرار گرفته و در Explorer/Taskbar نمایش داده می‌شود.
- [ ] نام فایل خروجی `DolphinDesk.exe` است.
- [ ] `FileDescription`, `ProductName`, `OriginalFilename`, `CompanyName` صحیح هستند.
- [ ] نام داخل UI و اعلان‌ها بازبینی شده است.
- [ ] یک دستگاه جدید بدون تنظیمات قبلی، با سرور اختصاصی کار می‌کند.
- [ ] کلید عمومی سرور درست و تنظیمات مشتری طبق سیاست محصول محدود شده‌اند.
- [ ] اتصال دوطرفه، کنترل موس/کیبورد، انتقال فایل، Clipboard و صدا مطابق محدودیت‌های تعیین‌شده تست شده‌اند.
- [ ] اجرای ZIP روی Windows تمیز تست شده است.
- [ ] محدودیت‌های مدنظر در سطح واقعی سیاست/موتور (نه فقط مخفی‌سازی UI) بررسی شده‌اند.
- [ ] الزامات مجوز نرم‌افزار RustDesk و کتابخانه‌های ثالث، از جمله AGPL-3.0، قبل از توزیع رعایت شده است.
- [ ] نسخه قابل توزیع و شماره نسخه مشخص، تست و آرشیو شده‌اند.

## 9) عیب‌یابی کوتاه

| پیام | بررسی اولیه |
| --- | --- |
| `stdlib.h file not found` | محیط MSVC با VsDevCmd در همان PowerShell فعال شده؟ `INCLUDE` و `LIB` مقدار دارند؟ |
| `bridge_generated.rs not found` | Code Generator نسخه 1.80.1 و فایل‌های تولیدشده را بررسی کنید. |
| `NativeFunction<...> can't be assigned to bool` | خروجی ffigen/Bridge و مسیر Clang را بررسی کنید؛ کد UI را دسته‌جمعی ویرایش نکنید. |
| `cargo build failed` پس از `Finished release` | وجود `librustdesk.dll` و محل `CARGO_TARGET_DIR` / Junction را بررسی کنید. |
| EXE باز نمی‌شود | وجود DLLهای Windows و پوشه `data` در کنار فایل EXE، لاگ اجرا و Event Viewer را بررسی کنید. |

**قاعده مهم:** برای تغییرات صرفاً Flutter، Cargo clean، حذف کل cache، نصب مجدد ابزارها یا تغییر IP سرور لازم نیست.
