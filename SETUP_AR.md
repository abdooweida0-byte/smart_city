# خطوات التشغيل (3 حاجات بس)

1. **Firebase**: من console.firebase.google.com اعمل مشروع، وفعّل Authentication (Email/Password) و Firestore Database، وأضف تطبيق Android باسم الحزمة `app.smartcity.smart_city`، ونزّل `google-services.json` وحطه في `android/app/`. انسخ محتوى `firestore.rules` في تبويب Rules وانشره.
2. **Cloudinary**: حساب مجاني، ثم Settings > Upload > Add upload preset (Signing Mode: Unsigned)، وحط `cloudName` و`uploadPreset` في `lib/core/constants.dart`.
3. **التشغيل**: `flutter pub get` ثم `flutter run`.

**حساب المسؤول**: سجّل حساب عادي من التطبيق، وبعدها من Firestore افتح `users/{uid}` وغيّر الحقل `role` إلى `admin`.
