# 🌍 World Radio

تطبيق راديو عالمي احترافي مبني بالكامل باستخدام **Flutter**. يتيح الاستماع المباشر لأكثر من **40,000 محطة إذاعية** حول العالم بجودة عالية وبدون انقطاع.

---

## 📁 هيكلية المشروع (Project Structure)
```
world_radio/
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
├── android/
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradle.properties
│   └── app/
│       ├── build.gradle
│       └── src/main/
│           ├── AndroidManifest.xml
│           ├── kotlin/com/worldradio/app/MainActivity.kt
│           └── res/
│               ├── drawable/launch_background.xml
│               └── values/styles.xml
└── lib/
    ├── main.dart
    ├── constants/
    ├── models/
    ├── providers/
    ├── screens/
    ├── services/
    └── widgets/
```

---

## 🚀 التشغيل المباشر من GitHub

### 1. الاستنساخ والتثبيت:
```bash
git clone https://github.com/YOUR_USERNAME/world_radio.git
cd world_radio
flutter pub get
```

### 2. التشغيل للتجربة:
```bash
flutter run
```

### 3. بناء نسخة الإنتاج:
```bash
flutter build apk --release
# أو للمتجر
flutter build appbundle --release
```
