# طريقة الرفع والبناء من GitHub Actions

1. أنشئ مستودع GitHub جديدًا.
2. ارفع **كل محتويات المشروع**، وليس ملفات الكود وحدها.
3. تأكد أن هذا المسار ظهر داخل المستودع:

```text
.github/workflows/build.yml
```

4. افتح تبويب **Actions**.
5. اختر **Build KiraLocket Dylib**.
6. اضغط **Run workflow** ثم شغّل البناء.
7. بعد ظهور العلامة الخضراء، افتح نتيجة التشغيل وانزل إلى قسم **Artifacts**.
8. نزّل الملف الذي يبدأ اسمه بـ:

```text
KiraLocket-arm64-
```

ستجد داخله:

```text
KiraLocket.dylib
KiraLocket.plist
KiraLocket-Injection.zip
BUILD_INFO.txt
SHA256SUMS.txt
```

لا تحتاج إلى إضافة Secrets، ولا ترفع ملف IPA أو ديلب SATLocket إلى المستودع. الـAction يبني من كود مشروع KiraLocket فقط.

## ملاحظة خاصة بالرفع من ويندوز

GitHub قد يلغي صلاحية تشغيل ملفات `.sh` عند رفعها من المتصفح. الإصدار 1.1.1 يعالج هذا تلقائيًا داخل الـWorkflow باستعمال `chmod` وتشغيل السكربت بواسطة `bash`، لذلك لا تحتاج إلى تعديل الصلاحيات يدويًا.

## ملاحظة عن ملف Tweak.xm

عدم وجود `Tweak.xm` مقصود وليس نقصًا. هذا المشروع يبني ديلب Standalone بدون Logos أو CydiaSubstrate. ملف `KiraEntry.m` هو نقطة بدء الديلب، وملف `KiraRuntime.m` يثبت التعديلات باستعمال Objective-C Runtime.
