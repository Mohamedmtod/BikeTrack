# الخطة الهندسية الشاملة — نظام إدارة رحلات العجلة والمشي على iOS

الإصدار: 1.1 — Approved with Technical Corrections — أكتوبر 2026
المنصة: iOS 16+ (المستهدف iOS 17+) — Flutter للواجهة + Swift Native للحساسات والخلفية
بيئة التطوير: Windows + بيئة macOS سحابية للبناء والتوقيع

> ملاحظة: كل القيم الرقمية في الملف ده (حدود الدقة، المهل الزمنية، السرعات) **قيم مبدئية** هتتظبط بعد الاختبار الميداني. أي سلوك iOS متعلّم بـ "تحقق" لازم يتأكد عمليًا على جهاز حقيقي (iPhone 14 Pro).

## سجل التعديلات — الإصدار 1.1

الخطة معتمدة كأساس رسمي، مع 6 تعديلات إلزامية قبل التنفيذ:

| # | التعديل | الأقسام المتأثرة |
|---|---------|-----------------|
| C1 | التتبع في الخلفية مش مضمون؛ iOS ممكن ينهي التطبيق، و`applicationWillTerminate` مش مضمون يتنفذ. التصميم مبني على **الاستعادة** مش الاستمرار. | 6.3، 8، M3 |
| C2 | NFC في الخلفية بيعرض إشعار لازم يتضغط، و**Custom URL Scheme مش مدعوم** في Background Tag Reading → Universal Link إجباري. زر بدء يدوي دائمًا. | 9، M2 |
| C3 | فصل `last_received_point` عن `last_distance_anchor` وإعادة تهيئة المرجع بعد التوقف أو الفجوة، لمنع قفزة مسافة عند الاستئناف. | 7.2 |
| C4 | NFC = نية المستخدم، مش دليل نشاط. يدخل في قرار بدء الرحلة فقط، مش في تصنيف النشاط. | 6.2، 7.6 |
| C5 | HealthKit يتأجل لحد ما التسجيل المحلي يثبت، ويتختبر إنشاء/إعادة محاولة/تصحيح/حذف على الجهاز. | 10، M5 |
| C6 | أول بوابة = إثبات البناء والتوقيع والتثبيت والوصول للحساسات على الجهاز، قبل أي اشتراك مدفوع أو بناء باقي النظام. | 14، M0 |

قرارات إضافية مثبتة:
- البداية أصغر: M0 ثم M1 ثم M2. الـ NativeEventBuffer الكامل والمصنّف المدمج الكامل يتأجلوا لحد ما البيانات الخام تثبت إنها بتوصل وبتتحفظ.
- `distance = 0` ما يعنيش "مسافة معروفة". المسافة ليها حالة: `measured` / `partial` / `unknown`.
- مفيش وعد بدقة محددة. معيار النجاح الأول: **صفر مسافة وهمية**، وبعدها نقيس الدقة والتصنيف والبطارية.
- Dart لاختبار المنطق على Windows، وSwift على الجهاز لاختبار سلوك iOS الحقيقي. الاختبارات الاصطناعية وحدها مش بتثبت إن الخلفية شغالة.

---

## 0. فهرس

1. الأهداف والنطاق
2. المبادئ الهندسية
3. المعمارية العامة
4. اختيار التقنيات ونوع كل مكوّن
5. نموذج البيانات (الجداول والأنواع)
6. آلات الحالة (النشاط / الرحلة / التسجيل)
7. الخوارزميات والحسابات
8. سلوك الخلفية على iOS
9. NFC
10. HealthKit
11. الصلاحيات و Info.plist و Capabilities
12. معالجة الأعطال والسيناريوهات
13. استراتيجية الاختبار
14. بيئة التطوير والبناء والتوقيع
15. خطة التنفيذ خطوة بخطوة (Milestones)
16. مقاييس النجاح
17. المخاطر والبدائل
18. قائمة مراجعة نهائية

---

## 1. الأهداف والنطاق

### 1.1 الهدف
نظام يسجل رحلات العجلة بدقة، ويفصلها عن المشي والمواصلات، و:
- ما يحسبش مسافة وهمية لو نسيت تقفل الرحلة.
- ما ينساش نفسه شغال للأبد.
- يعلّم أي جزء مش متأكد منه للمراجعة بدل التخمين.
- يستهلك بطارية مقبولة.

### 1.2 داخل النطاق (النسخة الأولى حتى الرابعة)
- اكتشاف النشاط (Core Motion).
- تتبع GPS لرحلات العجلة فقط.
- تأكيد بداية العجلة بـ NFC (اختياري).
- آلة حالات للرحلة مع Pause / Review / Auto-close.
- تخزين محلي + تصدير CSV.
- مراجعة وتصحيح يدوي.
- كتابة رحلات العجلة المؤكدة في HealthKit.

### 1.3 خارج النطاق حاليًا
- حساس BLE للعجلة (مرحلة لاحقة).
- Apple Watch.
- مزامنة سحابية / حسابات مستخدمين.
- أندرويد.

---

## 2. المبادئ الهندسية

| # | المبدأ | التطبيق العملي |
|---|--------|----------------|
| P1 | فصل النشاط عن الرحلة عن التسجيل | 3 آلات حالة مستقلة متواصلة بالأحداث |
| P2 | Event Sourcing | كل حاجة بتتسجل كحدث خام append-only، والحالة تُشتق منه |
| P3 | لا مسافة بدون دليل حركة | المسافة = نقاط GPS مقبولة **و** النشاط مش stationary |
| P4 | Unknown أفضل من تخمين | أي تعارض = unknown + needs_review |
| P5 | المنطق نقي وقابل للاختبار | State machine في Dart بدون أي اعتماد على iOS → تتختبر على Windows |
| P6 | الحساسات Native | Core Motion / Core Location / NFC / HealthKit بـ Swift عبر Platform Channels |
| P7 | قيم قابلة للضبط | كل threshold في ملف Config واحد، مش hard-coded |
| P8 | Idempotency | إعادة تشغيل نفس الأحداث تطلع نفس النتيجة بالظبط |

---

## 3. المعمارية العامة

```
┌──────────────────────────────────────────────────────────┐
│                     Flutter (Dart)                       │
│                                                          │
│  UI Layer        : Screens, Review, Stats, Settings      │
│  App Layer       : TripController (Riverpod)             │
│  Domain (PURE)   : ActivityClassifier                    │
│                    TripStateMachine                      │
│                    DistanceCalculator / GpsFilter        │
│  Data Layer      : Repositories → SQLite (drift)         │
│  Bridge          : MethodChannel / EventChannel          │
└──────────────────────────┬───────────────────────────────┘
                           │ Platform Channels
┌──────────────────────────┴───────────────────────────────┐
│                     iOS Native (Swift)                   │
│                                                          │
│  MotionService    : CMMotionActivityManager, CMPedometer │
│  LocationService  : CLLocationManager, SLC, Regions,     │
│                     CLBackgroundActivitySession (17+)    │
│  NfcService       : CoreNFC + Universal Link handler     │
│  HealthService    : HealthKit, HKWorkoutBuilder,         │
│                     HKWorkoutRouteBuilder                │
│  NativeEventBuffer: يخزن الأحداث محليًا لو Flutter مش جاهز│
│  NotificationSvc  : UNUserNotificationCenter             │
└──────────────────────────────────────────────────────────┘
```

### 3.1 قاعدة مهمة: الـ Native Event Buffer
لما iOS يصحّي التطبيق في الخلفية (SLC / Region)، محرك Flutter ممكن يكون لسه ما اشتغلش. عشان كده:
- طبقة Swift **تكتب الحدث فورًا** في ملف/SQLite native صغير (append-only).
- لما Flutter يجهز، يسحب الأحداث المعلّقة ويعالجها بالترتيب.
- ده يمنع ضياع أي حدث وقت الصحيان.

### 3.2 تدفق الأحداث
```
Sensor → Swift Service → NativeEventBuffer → EventChannel
      → Dart EventIngestor → events table
      → ActivityClassifier → ActivityState
      → TripStateMachine(event, state) → newState + commands
      → Commands (startGPS / stopGPS / notify / writeHealth) → Swift
```

الـ State Machine **ما بتنفذش** حاجة بنفسها؛ بترجع أوامر (Commands)، وطبقة التطبيق تنفذها. ده اللي بيخليها نقية وقابلة للاختبار.

---

## 4. اختيار التقنيات ونوع كل مكوّن

| المكوّن | التقنية | النوع | السبب |
|--------|---------|------|-------|
| الواجهة | Flutter 3.x / Dart 3 | Cross-platform UI | بتشتغل عليها من Windows |
| إدارة الحالة | Riverpod | Dart package | بسيط وقابل للاختبار |
| قاعدة البيانات | drift (SQLite) | Dart package | Typed queries + migrations + بيشتغل في tests على Windows |
| نماذج البيانات | freezed + json_serializable | Codegen | Immutable + copyWith للـ state machine |
| النشاط | CMMotionActivityManager | iOS Native | تصنيف walking/cycling/automotive/stationary + history 7 أيام |
| الخطوات | CMPedometer | iOS Native | خطوات + cadence + history |
| الموقع | CLLocationManager | iOS Native | GPS + background updates |
| الصحيان | Significant Location Change + CLCircularRegion | iOS Native | إعادة تشغيل التطبيق من الخلفية |
| جلسة الخلفية | CLBackgroundActivitySession | iOS 17+ | تحافظ على location في الخلفية |
| NFC | CoreNFC + Background Tag Reading (NDEF URL) | iOS Native | تأكيد بداية العجلة |
| Health | HealthKit | iOS Native | قراءة الخطوات، كتابة Workouts |
| الإشعارات | UNUserNotificationCenter | iOS Native | تنبيه "نسيت تقفل؟" |
| الجسر | MethodChannel + EventChannel (أو Pigeon) | Flutter | Pigeon أفضل: typed ويولّد كود Swift/Dart |
| CI/Build | Codemagic أو GitHub Actions macOS | Cloud | البناء والتوقيع من غير Mac |
| التوزيع | TestFlight | Apple | تثبيت على الآيفون |
| التحليل | Python/pandas أو Dart script | Offline | تحليل ملفات CSV |

**قرار:** نستخدم **Pigeon** للجسر بدل MethodChannel الخام، عشان الأنواع تبقى مضمونة بين Dart و Swift.

---

## 5. نموذج البيانات

### 5.1 الأنواع (Enums)

```dart
enum ActivityType { stationary, walking, running, cycling, automotive, unknown }
enum Confidence  { low, medium, high }

enum TripStatus {
  pending,      // NFC اتلمس، مستني تأكيد حركة
  active,       // رحلة شغالة وبتسجل
  paused,       // سكون قصير، الرحلة مفتوحة
  suspectedForgotten, // سكون طويل أو نشاط مختلف
  needsReview,  // اتقفلت لكن فيها شك
  completed,    // مؤكدة ومحفوظة
  cancelled,    // NFC من غير حركة
  autoClosed,   // اتقفلت تلقائيًا بعد التعليق
}

enum SegmentType  { cycling, walking, automotive, unknown, gap }
enum RecordingState { off, lowPower, highAccuracy }
enum EventSource  { motion, pedometer, gps, nfc, user, system, health }
enum ClassificationSource { coreMotion, fused, nfc, user }
```

### 5.2 الجداول

#### `events` (append-only — مصدر الحقيقة)
| العمود | النوع | ملاحظة |
|-------|------|-------|
| id | INTEGER PK AUTOINCREMENT | |
| ts_utc | INTEGER | ms منذ epoch |
| source | TEXT | EventSource |
| type | TEXT | مثلًا `activity_changed`, `location`, `nfc_scan`, `app_launched_bg`, `app_terminated` |
| payload | TEXT (JSON) | البيانات الخام |
| trip_id | TEXT NULL | لو مرتبط برحلة |
| processed | INTEGER (0/1) | هل الـ state machine عالجته |

#### `trips`
| العمود | النوع |
|-------|------|
| trip_id | TEXT PK (UUID v4) |
| status | TEXT (TripStatus) |
| start_time_utc | INTEGER |
| end_time_utc | INTEGER NULL |
| last_movement_utc | INTEGER NULL |
| bike_id | TEXT NULL |
| nfc_confirmed | INTEGER (0/1) |
| total_distance_m | REAL NULL |
| distance_status | TEXT (measured / partial / unknown) |
| moving_duration_s | INTEGER |
| paused_duration_s | INTEGER |
| suspended_duration_s | INTEGER |
| review_reason | TEXT NULL |
| created_at / updated_at | INTEGER |

#### `segments`
| العمود | النوع |
|-------|------|
| segment_id | TEXT PK |
| trip_id | TEXT FK |
| type | TEXT (SegmentType) |
| start_utc / end_utc | INTEGER |
| distance_m | REAL NULL (null = غير معروفة، مش صفر) |
| distance_status | TEXT (measured / partial / unknown) |
| moving_s | INTEGER |
| confidence | REAL (0..1) |
| classification_source | TEXT |
| user_corrected | INTEGER (0/1) |
| needs_review | INTEGER (0/1) |
| health_workout_uuid | TEXT NULL |
| health_synced_at | INTEGER NULL |

#### `gps_points`
| العمود | النوع |
|-------|------|
| id | INTEGER PK |
| segment_id | TEXT FK |
| ts_utc | INTEGER |
| lat / lon | REAL |
| altitude_m | REAL |
| h_accuracy_m | REAL |
| v_accuracy_m | REAL |
| speed_mps | REAL |
| speed_accuracy_mps | REAL |
| course_deg | REAL |
| accepted | INTEGER (0/1) |
| reject_reason | TEXT NULL |

> نخزن النقاط المرفوضة كمان (accepted=0) عشان نقدر نحلل ونظبط الفلاتر بعدين.

#### `activity_samples`
| العمود | النوع |
|-------|------|
| ts_utc | INTEGER |
| stationary / walking / running / cycling / automotive / unknown | INTEGER (0/1) |
| confidence | INTEGER (0=low,1=med,2=high) |

#### `bikes`
| bike_id | name | nfc_payload | created_at |

#### `config` (key/value)
لكل threshold قيمة قابلة للتعديل من شاشة Debug.

### 5.3 Indexes
- `events(ts_utc)`, `events(processed)`
- `gps_points(segment_id, ts_utc)`
- `segments(trip_id)`
- `trips(status)`

### 5.4 قاعدة الإجماليات
الإجماليات **ما تتخزنش كمصدر حقيقة**؛ `trips.total_distance_m` = مجموع `segments.distance_m` حيث `type = cycling`، وبتتحسب تاني بعد أي تصحيح.

في الإحصائيات بنعرض رقمين منفصلين: **المسافة المقاسة** (measured بس)، و**عدد/مدة الأجزاء غير المكتملة**. الجزء المجهول عمره ما يتحسب صفر ولا يتضاف كتقدير من غير موافقة.

---

## 6. آلات الحالة

### 6.1 آلة النشاط (Activity)
المدخلات: CMMotionActivity + cadence + سرعة GPS (لو متاحة).
المخرجات: `ActivityState { type, confidence, since }`.

قواعد:
- التغيير ما يحصلش إلا بعد ما النوع الجديد يستمر **مدة hysteresis**:
  - إلى cycling: 30 ث
  - إلى walking: 20 ث
  - إلى automotive: 60 ث
  - إلى stationary: 45 ث
- أي تعارض قوي → `unknown`.

### 6.2 آلة الرحلة (Trip)

```
            nfc_scan / user_start
   Idle ─────────────────────────────► Pending
    ▲                                    │  cycling مؤكد خلال T_pending
    │       timeout بدون حركة            ▼
    │  ◄──────── Cancelled ◄──────── (timeout)
    │                                  Active ◄──────────────┐
    │                                    │ stationary ≥ T_pause │ movement
    │                                    ▼                     │
    │                                  Paused ─────────────────┘
    │                                    │ stationary ≥ T_forgot
    │                                    │ أو automotive/walking طويل
    │                                    ▼
    │                            SuspectedForgotten
    │                       ┌────────────┼──────────────┐
    │          user confirms│   T_autoclose│    movement cycling
    │              end      ▼            ▼              ▼
    └──────────────── Completed     AutoClosed       Active
                         ▲               │
                         └── NeedsReview ◄┘ (user review)
```

#### جدول الانتقالات
| من | الحدث / الشرط | إلى | الأوامر |
|----|---------------|----|--------|
| Idle | nfc_scan | Pending | سجل start_candidate، شغّل Location lowPower |
| Idle | user_start | Active | startGPS(high) |
| Idle | cycling مؤكد ≥ 60ث (auto-detect) | Active | startGPS(high)، start_time = بداية النشاط من history |
| Pending | cycling مؤكد خلال T_pending | Active | startGPS(high) |
| Pending | مرور T_pending بدون حركة | Cancelled→Idle | stopGPS |
| Active | stationary ≥ T_pause | Paused | GPS → lowPower، region حوالين المكان |
| Active | walking مؤكد ≥ T_mode | Active (segment جديد walking) | اقفل segment العجلة |
| Active | automotive مؤكد ≥ T_mode | Active (segment automotive, needs_review) | المسافة ما تتحسبش عجلة |
| Active | GPS lost ≥ T_gap | Active (segment gap) | لا مسافة |
| Paused | حركة cycling | Active | GPS → high |
| Paused | stationary ≥ T_forgot | SuspectedForgotten | notify |
| SuspectedForgotten | user "أنهيت" | Completed | end = last_movement |
| SuspectedForgotten | user "لسه راكب" | Active | |
| SuspectedForgotten | مرور T_autoclose | AutoClosed | end = last_movement، stopGPS |
| AutoClosed | review | Completed / تعديل | |
| أي حالة مفتوحة | nfc_scan جديد | نفس الحالة + طلب قرار | اعرض الرحلة القديمة |
| أي حالة | app_relaunch بعد فجوة | نفس الحالة + reconcile | استعلام history |

> (C4) الـ `nfc_scan` بيأثر على **آلة الرحلة** بس: بيحط الرحلة في Pending ويقلل مهلة التأكيد، لكنه ما بيغيّرش تصنيف النشاط. لو Core Motion ما أكدش حركة، الرحلة تتلغي حتى لو الملصق اتلمس. وزر البدء اليدوي متاح دايمًا كبديل مساوي لـ NFC.

### 6.3 آلة التسجيل (Recording)
| الحالة | desiredAccuracy | distanceFilter | الاستخدام |
|--------|-----------------|----------------|-----------|
| off | — | — | Idle |
| lowPower | kCLLocationAccuracyHundredMeters | 50 م | Pending / Paused (يحافظ على صحيان التطبيق) |
| highAccuracy | kCLLocationAccuracyBest | 5 م | Active cycling |

إعدادات ثابتة لـ CLLocationManager:
- `activityType = .fitness` (أو `.otherNavigation`)
- `allowsBackgroundLocationUpdates = true`
- `pausesLocationUpdatesAutomatically = false` (إحنا اللي بنتحكم في الإيقاف)
- `showsBackgroundLocationIndicator = true`

> قاعدة حرجة: **ما نقفلش الـ location خالص** وإحنا في الخلفية والرحلة مفتوحة؛ لو قفلناه غالبًا مش هنعرف نرجّعه لحد ما حاجة تصحّي التطبيق. بنخفّضه لـ lowPower بس. (تحقق على الجهاز)

> (C1) الإعدادات دي **بتحسّن فرص** الاستمرار في الخلفية لكنها **مش ضمان**. iOS ممكن ينهي التطبيق في أي وقت (ضغط ذاكرة، حرارة، تحديث، إلخ). عشان كده:
> - كل انقطاع لازم يظهر في البيانات كـ gap صريح، مش كمسافة صفر.
> - التطبيق عند أي صحيان أو فتح يعمل reconcile (7.7) ويكمّل الرحلة المفتوحة.
> - الاعتماد على الأحداث اللي النظام بيسلّمها فعلًا: SLC، والخروج من Region، والفتح اليدوي، والـ history بتاع Core Motion.

### 6.4 ملف القيم المبدئية (Config)
| المفتاح | القيمة المبدئية |
|--------|-----------------|
| T_pending | 5 دقائق |
| T_pause | 3 دقائق |
| T_forgot | 15 دقيقة |
| T_autoclose | 45 دقيقة |
| T_mode (تغيير وسيلة) | 60 ث |
| T_gap (فقدان GPS) | 30 ث |
| MAX_H_ACCURACY | 25 م |
| MAX_SPEED_CYCLING | 16.7 م/ث (60 كم/س) |
| MIN_STEP_DISTANCE | 3 م |
| MAX_ACCEL | 4 م/ث² |
| CADENCE_WALKING_MIN | 1.2 خطوة/ث |
| PAUSE_REGION_RADIUS | 100 م |

---

## 7. الخوارزميات والحسابات

### 7.1 المسافة بين نقطتين — Haversine
\[
a = \sin^2\!\left(\frac{\Delta\varphi}{2}\right) + \cos\varphi_1 \cos\varphi_2 \sin^2\!\left(\frac{\Delta\lambda}{2}\right)
\]
\[
d = 2R \cdot \operatorname{atan2}\!\left(\sqrt{a}, \sqrt{1-a}\right), \quad R = 6\,371\,000 \text{ م}
\]
(φ و λ بالراديان.) الدقة كافية تمامًا لمسافات العجلة.

### 7.2 فلتر قبول نقطة GPS (بالترتيب)
(C3) بنحتفظ بمرجعين منفصلين:
- `last_received_point`: آخر نقطة وصلت (للتسارع والسرعة اللحظية والتشخيص).
- `last_distance_anchor` \(p_a\): النقطة اللي المسافة بتتحسب منها.

قواعد إعادة تهيئة المرجع (`anchor = null`):
- دخول Paused أو stationary مؤكد.
- فجوة GPS أكبر من T_gap.
- تغيير segment (نوع نشاط جديد).
- صحيان التطبيق بعد انقطاع.

لما `anchor = null`: أول نقطة مقبولة بعد الاستئناف تبقى المرجع الجديد **بمسافة صفر**. مفيش مسافة بتتحسب عبر فجوة أو توقف أبدًا. الجزء الناقص يتسجل كـ gap بحالة مسافة `unknown`.

لكل نقطة جديدة \(p_i\) مقابل المرجع \(p_{a}\):

- بعد البنود 1–4: لو `anchor = null` → النقطة تبقى المرجع الجديد، ومسافتها صفر (`anchor_reset`)، ونوقف هنا.

1. `h_accuracy < 0` → رفض (`invalid`).
2. `h_accuracy > MAX_H_ACCURACY` → رفض (`low_accuracy`).
3. عمر النقطة (now − timestamp) > 10 ث → رفض (`stale`).
4. \(\Delta t = t_i - t_a \le 0\) → رفض (`out_of_order`).
5. \(d = \text{haversine}(p_a, p_i)\)، \(v = d / \Delta t\).
6. \(v >\) MAX_SPEED_CYCLING → رفض (`impossible_speed`).
7. التسارع \(|v - v_{prev}| / \Delta t >\) MAX_ACCEL → رفض (`spike`). (السرعة السابقة \(v_{prev}\) محسوبة من `last_received_point`.)
8. النشاط الحالي = stationary → النقطة تتخزن لكن **مسافتها = 0**، والمرجع يتصفّر عند تأكيد التوقف (`stationary_gate`).
9. \(d < \max(\text{MIN\_STEP\_DISTANCE}, \; 0.5 \cdot (acc_a + acc_i))\) → ما نضيفش مسافة لكن ما نحركش النقطة المرجعية (`jitter`).
10. غير كده → مقبولة، أضف \(d\) للمسافة، و \(p_a \leftarrow p_i\).

> البند 9 هو أهم دفاع ضد المسافة الوهمية: الحركة لازم تكون أكبر من نصف مجموع نطاقي عدم اليقين.

### 7.3 تنعيم (اختياري في النسخة 2+)
فلتر Kalman بسيط 1D لكل من lat/lon، أو متوسط متحرك على 3 نقاط. نقارن المسافة الخام والمنعّمة في الاختبار ونختار.

### 7.4 المدد
- `moving_duration` = مجموع \(\Delta t\) بين نقاط مقبولة متتالية حيث \(v \ge 0.8\) م/ث **و** \(\Delta t \le\) 30 ث.
- `paused_duration` = مجموع الفترات في حالة Paused.
- `suspended_duration` = الفترات في SuspectedForgotten.
- `total_duration` = end − start.
- السرعة المتوسطة = distance / moving_duration (مش total).

### 7.5 قص ذيل الرحلة المنسية
عند AutoClosed أو تأكيد الإنهاء بعد نسيان:
- `end_time = last_movement_utc` (آخر نقطة مقبولة بسرعة ≥ 0.8 م/ث أو آخر activity cycling).
- أي نقاط بعده تتنقل لـ segment `gap` أو تتشال من الحساب.

### 7.6 المصنّف المدمج (Fused Classifier)
لكل نافذة 30 ثانية نحسب score لكل نوع:

```
score[cycling]    = w1*CM_cycling*conf + w2*S_speed_cyc + w3*(1 - S_cadence)
score[walking]    = w1*CM_walking*conf + w2*S_speed_walk + w3*S_cadence
score[automotive] = w1*CM_auto*conf    + w2*S_speed_auto + w5*S_stop_pattern
score[stationary] = w1*CM_stat*conf    + w2*(v_avg < 0.5)
```
- `conf`: low=0.3, medium=0.6, high=1.0
- `S_cadence` = min(1, cadence / 1.8)
- `S_speed_*` = دالة عضوية (membership) ناعمة حسب متوسط/وسيط السرعة في النافذة:
  - walking: ذروة 1–2 م/ث
  - cycling: ذروة 3–9 م/ث
  - automotive: ذروة > 8 م/ث
- `S_stop_pattern`: نسبة توقفات طويلة + تسارعات عالية (سلوك العربية).
- (C4) **NFC مش داخل في المصنّف**. هو دليل على النية، مش على الحركة. تأثيره في آلة الرحلة بس (6.2).
- أوزان مبدئية: w1=0.55، w2=0.30، w3=0.15، w5=0.10. السرعة وحدها مش كفاية للتفريق بين العجلة والعربية.
- الأوزان والحدود النهائية بتتحدد من بيانات الاختبار المصححة يدويًا (M7)، مش من الأرقام دي.
- (قرار إضافي) المصنّف المدمج الكامل **ما يتنفذش قبل M4**. في M2–M3 بنسجل تصنيف Core Motion الخام بس، ونحلله.

القرار:
- `best = argmax(score)`
- لو `score[best] < 0.45` **أو** `score[best] − score[second] < 0.15` → `unknown`.

> المصنّف يتعلّم بعد الاختبار: الأوزان والحدود بتتظبط من ملفات CSV المصححة يدويًا.

### 7.7 استرجاع بداية الرحلة (Reconciliation)
عند أي صحيان أو فتح التطبيق بعد فجوة:
1. `queryActivityStarting(from: lastProcessedTs, to: now)`.
2. `queryPedometerData(from:, to:)`.
3. لو فيه cycling قبل بداية الـ GPS → نعمل segment `cycling` بمسافة **غير معروفة** (`distance_m = null`, `distance_status = unknown`, needs_review) بدل ما نخترع رقم. والرحلة كلها تبقى `distance_status = partial`.
4. ممكن تقدير اختياري: المسافة ≈ مدة × متوسط سرعة المستخدم التاريخي، **يتعرض كتقدير منفصل** ومش يدخل الإجمالي إلا بعد الموافقة.

### 7.8 المشي (من غير GPS)
- المصدر: CMPedometer (`numberOfSteps`, `distance`, `currentCadence`).
- للمقارنة: قراءة `HKQuantityType.stepCount` من HealthKit لنفس الفترة.
- الفرق المتوقع بينهم يتسجل في التحليل، ومش بنكتب خطوات في Health أبدًا.

---

## 8. سلوك الخلفية على iOS

### 8.1 الآليات
| الآلية | بتعمل إيه | قيود |
|-------|----------|------|
| Background location (UIBackgroundModes: location) | يفضل التطبيق شغال وبيستقبل مواقع | لازم يبدأ وهو في المقدمة أو أثناء جلسة مسموحة |
| CLBackgroundActivitySession (iOS 17+) | يحافظ على الجلسة ويظهر المؤشر | iOS 17+ |
| Significant Location Change | يصحّي/يعيد تشغيل التطبيق عند تغيّر ~500م | ما يصحّيش بعد force-quit غالبًا؛ غير دقيق في التوقيت |
| Region Monitoring | يصحّي عند الخروج من دائرة | حد 20 منطقة؛ نصف قطر عملي ≥ 100 م |
| CMMotionActivity history | سجل 7 أيام حتى لو التطبيق مقفول | ما يصحّيش التطبيق |
| Local notifications | تنبيه المستخدم | محتاجة إذن |

### 8.2 استراتيجية الصحيان
- Idle: SLC شغال دايمًا (تكلفة بطارية قليلة جدًا).
- Paused: lowPower location + Region حوالين مكان الوقوف.
- Active: highAccuracy.
- كل صحيان → `app_launched_bg` event → reconcile (7.7).

### 8.3 Force-quit
- نعتبره حالة متوقعة.
- عند الفتح التالي: reconcile + أي فترة من غير GPS تبقى segment `gap` أو `cycling(distance=null)`.
- نعرض رسالة توضيحية للمستخدم مرة واحدة: "قفل التطبيق بالسحب بيوقف التتبع".

### 8.4 الحفظ الآمن
- كل كتابة في SQLite جوه transaction.
- `sceneDidEnterBackground` → flush.
- (C1) `applicationWillTerminate` **مش مضمون يتنفذ** (مش بيتنفذ مع force-quit أو لما النظام ينهي التطبيق وهو معلّق). عشان كده ما نعتمدش عليه:
  - كل حدث يتكتب فور وصوله (write-ahead)، مش مجمّع في الذاكرة.
  - snapshot للحالة كل 30 ث في Active.
  - عند الفتح: آخر timestamp محفوظ = بداية الفجوة المحتملة.

---

## 9. NFC

### 9.1 الملصق
- النوع: NTAG213/215 (NDEF، رخيص ومتوافق).
- المحتوى: سجل NDEF URI = Universal Link، مثال:
  `https://<your-domain>/nfc/start?bike=road1`
- (C2) **Custom URL Scheme مش مدعوم في Background Tag Reading**، فـ Universal Link إجباري للمسار ده. الـ Custom Scheme ينفع بس من جوه التطبيق (جلسة `NFCNDEFReaderSession` وهو مفتوح) أو من Shortcuts.
- اختياري: قفل الملصق read-only بعد الكتابة.

### 9.2 مسارات التفعيل (نجرب الاتنين)
1. **Background Tag Reading** (iPhone XS وأحدث): الآيفون يقرأ الملصق والشاشة مفتوحة → **إشعار لازم المستخدم يضغط عليه** → التطبيق يفتح بالـ Universal Link. المسح ما بيبدأش الرحلة بصمت.
2. **Shortcuts Personal Automation (NFC trigger):** تفتح التطبيق أو تنفذ App Intent. **يتختبر منفصل**، وما نفترضش إنه يقدر يبدأ GPS في الخلفية لحد ما نثبت ده عمليًا.
3. **App Intent** (`StartBikeTripIntent`) — يتنفذ من Shortcuts.
4. **زر بدء يدوي** في التطبيق (وممكن Widget أو Live Activity لاحقًا) — **متاح دايمًا**، وNFC مجرد وسيلة تأكيد اختيارية.

### 9.3 التعامل في التطبيق
- استقبال الـ link → `nfc_scan` event بـ `bike_id`.
- لو فيه رحلة مفتوحة → شاشة قرار (كمّل / اقفل القديمة وابدأ جديدة / راجع).
- وإحنا في المقدمة: ابدأ location فورًا (ده اللي بيضمن استمراره في الخلفية).

### 9.4 Universal Links (لو اخترناها)
- دومين + ملف `apple-app-site-association` على `/.well-known/`.
- Associated Domains capability: `applinks:<domain>`.
- ممكن استضافة مجانية (GitHub Pages / Cloudflare Pages) — تحقق من دعم الملف.

---

## 10. HealthKit

> (C5) HealthKit **آخر حاجة تتنفذ** (M5)، وبعد ما التسجيل المحلي يثبت. الكتابة في Health نتيجة للنظام المحلي، مش جزء من منطقه.

### 10.1 القراءة
- `HKQuantityType(.stepCount)`
- `HKQuantityType(.distanceWalkingRunning)`
- `HKQuantityType(.distanceCycling)` (لمنع التكرار مع تطبيقات تانية)
- `HKWorkoutType` (نفحص لو فيه workout عجلة من مصدر تاني في نفس الوقت)

### 10.2 الكتابة
- رحلة العجلة المؤكدة فقط (`completed` و `needs_review = 0`).
- `HKWorkoutBuilder` بـ `HKWorkoutConfiguration(activityType: .cycling, locationType: .outdoor)`.
- Samples: `distanceCycling` + `activeEnergyBurned` (اختياري، تقديري).
- المسار: `HKWorkoutRouteBuilder` من النقاط المقبولة.
- Metadata: `HKMetadataKeyExternalUUID = segment_id` + `HKMetadataKeySyncIdentifier` + `HKMetadataKeySyncVersion`.

### 10.3 منع التكرار
- **ما نكتبش خطوات أو مشي أبدًا.**
- قبل الكتابة: نتحقق إن مفيش workout cycling متداخل من مصدر تاني (Apple Watch مثلًا) → لو موجود نسأل المستخدم.
- نخزن `health_workout_uuid` في `segments`.
- عند تصحيح نوع الـ segment أو تعديله → نحذف الـ workout (`healthStore.delete`) ونكتبه تاني بـ SyncVersion أعلى.

### 10.4 (C5) سجل عمليات Health
ما نفترضش إن أي عملية نجحت أو إن بيانات الـ workout (الـ samples والـ route) هتتحدث تلقائيًا. جدول `health_ops`:

| العمود | النوع |
|-------|------|
| op_id | TEXT PK |
| segment_id | TEXT FK |
| op_type | TEXT (create / delete / replace) |
| sync_identifier | TEXT |
| sync_version | INTEGER |
| status | TEXT (pending / success / failed) |
| attempts | INTEGER |
| last_error | TEXT NULL |
| hk_workout_uuid | TEXT NULL |

### 10.5 اختبارات HealthKit على الجهاز (إلزامية في M5)
1. إنشاء workout + route ← التأكد إنهم ظاهرين في تطبيق Health.
2. إعادة المحاولة بعد فشل مصطنع ← مفيش تكرار.
3. نفس الـ segment يتكتب مرتين ← نسخة واحدة بس (SyncIdentifier).
4. تصحيح النوع ← القديم اتحذف والجديد ظاهر، ومعاه الـ samples والـ route.
5. حذف رحلة ← اتشالت من Health.
6. رفض صلاحية الكتابة ← التطبيق يكمل محليًا عادي.

---

## 11. الصلاحيات و Info.plist و Capabilities

### 11.1 Capabilities (في Xcode / Entitlements)
- Background Modes: `location` (+ `processing` اختياري)
- HealthKit
- Near Field Communication Tag Reading
- Associated Domains (لو Universal Links)
- Push Notifications: **مش محتاجين** (إشعارات محلية بس)

### 11.2 Info.plist
| المفتاح | الغرض |
|--------|------|
| NSLocationWhenInUseUsageDescription | تتبع الرحلة |
| NSLocationAlwaysAndWhenInUseUsageDescription | التتبع في الخلفية |
| NSMotionUsageDescription | اكتشاف المشي والعجلة |
| NSHealthShareUsageDescription | قراءة الخطوات |
| NSHealthUpdateUsageDescription | حفظ رحلات العجلة |
| NFCReaderUsageDescription | قراءة ملصق العجلة |
| UIBackgroundModes | `location` |
| com.apple.developer.nfc.readersession.formats | `NDEF` |

### 11.3 تسلسل طلب الأذونات (Onboarding)
1. Motion → 2. Location When In Use → 3. Location Always (بعد أول رحلة، مع شرح) → 4. Notifications → 5. Health → 6. NFC (عند أول استخدام).

ولو المستخدم رفض أي إذن: degraded mode واضح (مثلًا من غير Always = تتبع يدوي في المقدمة بس).

---

## 12. معالجة الأعطال والسيناريوهات

| # | السيناريو | الاكتشاف | التصرف | الحالة الناتجة |
|---|-----------|---------|--------|---------------|
| S1 | NFC + بدأت العجلة | nfc_scan ثم cycling ≥ 30ث | startGPS(high) | Active |
| S2 | NFC من غير ركوب | مرور T_pending | إلغاء | Cancelled |
| S3 | نسيت تقفل | stationary ≥ T_forgot | إشعار؛ end = last_movement | SuspectedForgotten → AutoClosed |
| S4 | إشارة مرور | stationary < T_pause | لا شيء، مسافة = 0 (stationary gate) | Active |
| S5 | نزلت ومشيت | walking ≥ T_mode | segment جديد walking | Active (مقاطع متعددة) |
| S6 | ميكروباص/عربية | automotive ≥ T_mode أو سرعة > حد | segment automotive، needs_review | Active/NeedsReview |
| S7 | GPS ضعيف | accuracy > حد أو مفيش نقاط ≥ T_gap | segment gap، لا مسافة | Active |
| S8 | Force-quit | فجوة في الأحداث عند الفتح | reconcile + gap | NeedsReview |
| S9 | البطارية خلصت / Restart | `app_launched` بعد فجوة كبيرة | reconcile، end = last_movement | AutoClosed/NeedsReview |
| S10 | رحلة جديدة وفيه قديمة مفتوحة | nfc_scan/user_start مع trip مفتوحة | شاشة قرار | حسب الاختيار |
| S11 | تصنيف غلط | المستخدم | تعديل النوع + إعادة حساب + تحديث Health | Completed |
| S12 | تغيّر المنطقة الزمنية | — | التخزين UTC، العرض محلي | — |
| S13 | رفض صلاحية Always | authorizationStatus | وضع يدوي + رسالة | — |
| S14 | Low Power Mode | `isLowPowerModeEnabled` | تحذير، distanceFilter أكبر | — |
| S15 | ساعة الجهاز اتغيرت | فرق كبير بين ts و monotonic | علّم الأحداث | NeedsReview |
| S16 | Pause طويل ثم رجعت ركبت | خروج من Region / حركة | استئناف | Active |

---

## 13. استراتيجية الاختبار

### 13.1 Unit tests (على Windows — `flutter test`)
- `GpsFilter`: كل reject_reason ليه test.
- `Haversine`: قيم معروفة (مثلًا نقطتين بفرق 0.001° خط عرض ≈ 111.2 م).
- `ActivityClassifier`: نوافذ مصطنعة لكل نوع + حالات التعارض → unknown.
- `TripStateMachine`: test لكل صف في جدول الانتقالات + كل سيناريو S1–S16.
- اختبارات خصائص (property tests): "المسافة ما تزيدش أبدًا لما النشاط stationary"، "end_time ≤ last_movement".

### 13.2 Replay tests (على Windows)
- ملفات CSV من رحلات حقيقية → تتشغل على المنطق → مقارنة بالـ ground truth.
- أي bug ميداني = ملف replay جديد يتضاف للـ tests (regression).

### 13.3 Golden scenarios (ملفات مصطنعة)
- `stationary_drift_30min.csv`: واقف 30 دقيقة → المسافة المتوقعة = 0.
- `traffic_light_stops.csv`: 5 وقفات 60 ث.
- `bike_then_walk.csv`، `bike_then_microbus.csv`، `gps_tunnel_gap.csv`.

### 13.4 Field tests (على الآيفون)
| الاختبار | العدد المقترح | القياس |
|---------|---------------|--------|
| مشي فقط | 5 | خطوات مقابل Health |
| عجلة مسار معروف | 10 | المسافة مقابل خريطة المسار |
| عربية/ميكروباص | 5 | هل اتعلّم automotive |
| مختلط | 5 | صحة المقاطع |
| نسيان متعمد | 5 | هل المسافة الوهمية = 0 تقريبًا |
| Force-quit | 3 | سلوك الاسترجاع |
| واقف في البيت ساعة والتطبيق فاتح رحلة | 3 | انحراف المسافة |
| بطارية | 3 رحلات ساعة | % في الساعة |

Ground truth: زرار "النوع الحقيقي" في شاشة Debug + NFC.

### 13.5 مصفوفة الخلط (Confusion Matrix)
نحسب من الـ segments المصححة:
- Precision و Recall لكل نوع.
- نسبة unknown.
- خطأ المسافة: \(\text{err} = \frac{|d_{app} - d_{ref}|}{d_{ref}}\).

---

## 14. بيئة التطوير والبناء والتوقيع

### 14.1 على Windows
- Flutter SDK + VS Code/Android Studio.
- كتابة كل كود Dart + الـ tests.
- كتابة كود Swift (من غير compile محلي) — في `ios/Runner/`.
- Git + GitHub.

### 14.2 macOS سحابي — الخيارات
| الخيار | التكلفة | المميزات | العيوب |
|-------|--------|---------|-------|
| Codemagic | فيه شريحة مجانية بدقائق محدودة (تحقق) | سهل مع Flutter، توقيع تلقائي، TestFlight | مفيش Xcode تفاعلي للـ debug |
| GitHub Actions macOS | دقائق مجانية محدودة للحسابات الشخصية (تحقق؛ macOS بيتحسب بمعامل أعلى) | مرن | إعداد التوقيع يدوي (fastlane) |
| Mac مؤجر (MacinCloud وغيره) | اشتراك | Xcode كامل + debug على الجهاز | تكلفة، بطء أحيانًا |
| Mac mini مستعمل | شراء مرة واحدة | أفضل تجربة | تكلفة أولية |

**الاقتراح:** Codemagic + TestFlight للبناء اليومي، ومع Mac مؤجر لساعات قليلة وقت debug مشاكل الخلفية لو احتجنا.

> (C6) **ما نشتريش أي اشتراك مدفوع، ولا نبني باقي المشروع، قبل ما بوابة M0 تتحسم.** الترتيب:
> 1. نجرب الأول المسار الأرخص (جلسة Mac مؤجرة قصيرة + Xcode + Personal Team مجاني) ونشوف أنهي capabilities شغالة فعلًا على الجهاز.
> 2. لو المسار المجاني منع حاجة أساسية (TestFlight أو التوقيع من CI أو capability مطلوبة) ← نشترك في Apple Developer Program.
> 3. نجاح build الـ Flutter **ما يعنيش** إن HealthKit وNFC والخلفية شغالين؛ كل واحدة ليها اختبار منفصل على الجهاز.

### 14.3 حساب Apple
- **Apple Developer Program (مدفوع سنويًا)** مطلوب عمليًا لـ TestFlight والتوقيع من CI.
- الحساب المجاني: محتاج Xcode محلي، والتطبيق بيقعد 7 أيام بس، وفيه قيود على بعض الـ capabilities (تحقق من HealthKit و NFC).

### 14.4 خطوات الإعداد
1. التسجيل في Apple Developer.
2. إنشاء App ID بالـ capabilities (HealthKit, NFC, Associated Domains).
3. إنشاء App Store Connect app record.
4. App Store Connect API Key → Codemagic.
5. Automatic code signing في Codemagic.
6. `codemagic.yaml`: build ipa → TestFlight.
7. تسجيل الآيفون كـ tester داخلي.

### 14.5 التسجيل التشخيصي (Debug Logging)
- شاشة Debug: آخر 200 حدث، الحالة الحالية، أزرار ground truth، تصدير CSV/JSON عبر Share Sheet.
- Logger native بـ `os.Logger` + ملف local.

---

## 15. خطة التنفيذ خطوة بخطوة

### M0 — بوابة الجدوى: البناء والتثبيت والحساسات (C6)
تطبيق صغير جدًا (Feasibility App)، مش المشروع الكامل:
- [ ] مشروع Flutter فاضي + كود Swift بسيط عبر MethodChannel.
- [ ] بناء وتوقيع وتثبيت على iPhone 14 Pro (بالمسار المختار في 14.2).
- [ ] قراءة Core Motion (activity حالي + history query) وعرضه.
- [ ] قراءة موقع واحد بـ Core Location + طلب Always.
- [ ] تشغيل location في الخلفية 15 دقيقة وتسجيل عدد النقاط والفجوات.
- [ ] قراءة ملصق NFC: جلسة داخل التطبيق + Background Tag Reading بـ Universal Link.
- [ ] طلب صلاحية HealthKit وقراءة الخطوات.
- **بوابة:** كل بند يتعلّم نجح / فشل / محتاج حساب مدفوع. **مفيش M1 الميداني قبل ما البوابة دي تتحسم.**

### M0.5 — هيكل المشروع الحقيقي
- [ ] إنشاء repo + هيكل المشروع:
```
lib/
  domain/        (pure: models, classifier, state_machine, gps_filter, geo)
  data/          (drift db, repositories)
  bridge/        (pigeon generated)
  app/           (controllers, providers)
  ui/            (screens)
  debug/         (debug screen, export)
ios/Runner/
  Services/      (MotionService, LocationService, NfcService, HealthService)
  EventBuffer/
  Bridge/
test/
  domain/ replay/ fixtures/
tools/           (analysis scripts)
```
- [ ] إعداد Flutter + drift + freezed + riverpod + pigeon.
- [ ] ملف Config.
- [ ] إعداد CI الدائم (Codemagic أو غيره) حسب نتيجة M0.

### M1 — المنطق النقي (الأسبوع 1–2، Windows بالكامل)
- [ ] Models + enums (القسم 5).
- [ ] `geo.dart`: haversine.
- [ ] `GpsFilter` (7.2) + tests.
- [ ] `ActivityClassifier` (7.6) + tests.
- [ ] `TripStateMachine` (6.2) + test لكل صف وسيناريو.
- [ ] Fixtures مصطنعة (13.3).
- **بوابة:** كل الـ tests خضرا + stationary_drift = 0 م.

### M2 — النسخة 1: مسجّل البيانات الخام + رحلة يدوية + NFC
- [ ] DB schema + migrations.
- [ ] Event log بسيط: كل حدث يتكتب فورًا (نسخة مبسطة من NativeEventBuffer؛ النسخة الكاملة في M3 لو البيانات أثبتت الحاجة ليها).
- [ ] تسجيل خام: activity + pedometer + GPS points + أحداث التطبيق.
- [ ] زر Start/Stop يدوي (المسار الأساسي).
- [ ] Swift: NfcService + Universal Link (+ صفحة AASA على الدومين).
- [ ] كتابة ملصق NFC.
- [ ] شاشة Debug + تصدير CSV.
- [ ] Field test: 10 لمسات NFC (مقدمة / خلفية / شاشة مقفولة) + اختبار Shortcuts منفصل.
- **بوابة:** البيانات الخام بتوصل وبتتحفظ كاملة، والرحلة اليدوية شغالة. NFC يتسجل نجاحه الفعلي (مش شرط ينجح في كل الحالات).

### M3 — النسخة 2: Core Motion + Core Location
- [ ] Swift: MotionService (live + history query).
- [ ] Swift: LocationService (3 أوضاع تسجيل، SLC، Regions، Background session).
- [ ] NativeEventBuffer.
- [ ] Pigeon APIs + EventChannel.
- [ ] ربط المصنّف والـ state machine بالأحداث الحقيقية.
- [ ] Field tests: مشي، عجلة، عربية، وقفات (13.4).
- **بوابة (C1):** اختبار تسجيل ساعة على الجهاز في الخلفية، مع **قياس** عدد الفجوات ومدتها والأحداث المفقودة، والتأكد إن كل فجوة ظاهرة صراحةً في البيانات وإن الاستعادة اشتغلت. البوابة مش "ضمان استمرار ساعة في كل الظروف".
- [ ] اختبار إعادة تهيئة مرجع المسافة (C3): وقوف 5 دقايق ثم استئناف، ونفق/GPS ضعيف ثم رجوع ← مفيش قفزة مسافة.

### M4 — النسخة 3: النسيان والمراجعة والتصحيح
- [ ] Paused / SuspectedForgotten / AutoClosed بالكامل.
- [ ] قص الذيل (7.5).
- [ ] Reconciliation (7.7) + gaps.
- [ ] إشعارات محلية.
- [ ] شاشة المراجعة: خريطة + المقاطع + تعديل النوع + دمج/تقسيم.
- [ ] إعادة حساب الإجماليات.
- [ ] Field tests: نسيان متعمد، force-quit، restart.
- **بوابة:** المسافة الوهمية بعد نسيان ساعة < حد نتفق عليه بعد القياس.

### M5 — النسخة 4: HealthKit (C5 — بعد ما التسجيل المحلي يثبت)
- [ ] HealthService: صلاحيات، قراءة، كتابة workout + route.
- [ ] جدول `health_ops` ومتابعة نتيجة كل عملية.
- [ ] منع التكرار بـ SyncIdentifier + SyncVersion.
- [ ] تحديث/حذف عند التصحيح.
- [ ] اختبارات 10.5 الست على الجهاز.
- [ ] مقارنة خطوات CMPedometer مع Health.
- **بوابة:** مفيش أي تكرار في تطبيق Health بعد 10 رحلات + تصحيحين.

### M6 — الواجهة والإحصائيات والتلميع
- [ ] الشاشة الرئيسية، سجل الرحلات، إحصائيات أسبوعية/شهرية.
- [ ] Onboarding للأذونات.
- [ ] إدارة العجلات والملصقات.
- [ ] تحسين البطارية حسب القياسات.

### M7 — المعايرة
- [ ] أسبوعين بيانات حقيقية.
- [ ] Confusion matrix + خطأ المسافة + البطارية.
- [ ] ضبط الأوزان والحدود في Config.
- [ ] تحديد أرقام الدقة المستهدفة **بناءً على القياس**.

---

## 16. مقاييس النجاح (تتحدد أرقامها بعد M7)

| المقياس | طريقة القياس | الهدف |
|--------|-------------|------|
| صحة تصنيف segments العجلة | Precision/Recall من المراجعة | يتحدد بعد القياس |
| نسبة Unknown | segments unknown ÷ الكل | أقل ما يمكن بدون زيادة الخطأ |
| خطأ مسافة العجلة | مقارنة بمسار معروف | يتحدد بعد القياس |
| **المسافة الوهمية وأنت واقف** (معيار النجاح الأول) | اختبار ساعة ثابت + نسيان متعمد | قريبة من صفر |
| قفزة المسافة بعد الاستئناف (C3) | وقوف/فجوة ثم حركة | صفر |
| شفافية الفجوات | كل انقطاع ظاهر كـ gap | 100% |
| البطارية | % / ساعة Active و Idle | يتحدد بعد القياس |
| ضياع الأحداث | فجوات غير مفسرة | يتقاس في M3، والهدف يتحدد بعدها |
| تكرار Health | مراجعة يدوية | 0 |

---

## 17. المخاطر والبدائل

| الخطر | الاحتمال | الأثر | التخفيف |
|------|---------|------|---------|
| Core Motion يتأخر أو يخلط العجلة بالعربية | عالي | متوسط | المصنّف المدمج + unknown + مراجعة (NFC للنية فقط) |
| iOS يوقف الـ location في الخلفية | متوسط | عالي | lowPower بدل الإيقاف، Background session، Region، reconcile |
| Force-quit | متوسط | متوسط | رسالة توعوية + reconcile + gap |
| NFC محتاج ضغطة على الإشعار | مؤكد | منخفض | زر يدوي دائم + Shortcuts (يتختبر) |
| Custom URL Scheme مش شغال في الخلفية | مؤكد | متوسط | Universal Link + دومين + AASA |
| قفزة مسافة بعد توقف/فجوة | عالي | عالي | فصل المرجعين + إعادة التهيئة (7.2) |
| بيئة البناء/التوقيع ما تدعمش capability مطلوبة | متوسط | عالي | بوابة M0 قبل أي اشتراك |
| تكرار أو بيانات قديمة في Health بعد التصحيح | متوسط | متوسط | health_ops + اختبارات 10.5 |
| تكلفة/تعقيد التوقيع من Windows | متوسط | عالي | بوابة M0 ثم اختيار CI المناسب |
| انحراف GPS | عالي | عالي | stationary gate + jitter threshold (7.2) |
| رفض المستخدم لصلاحية Always | متوسط | عالي | وضع يدوي واضح |
| تغيّر سلوك iOS بين الإصدارات | متوسط | متوسط | field tests بعد كل تحديث iOS كبير |
| البطارية | متوسط | متوسط | GPS للعجلة بس، أوضاع تسجيل متدرجة |

البديل المستقبلي: حساس BLE للعجلة كإشارة مؤكدة للدوران (Cycling Speed and Cadence Profile) يدخل المصنّف بوزن عالي.

---

## 18. قائمة مراجعة نهائية

### قبل كتابة كود Swift (بوابة M0)
- [ ] التطبيق التجريبي اتبنى واتثبت على iPhone 14 Pro
- [ ] Core Motion + Core Location شغالين على الجهاز
- [ ] NFC (Universal Link) وHealthKit اتختبروا
- [ ] قرار الحساب (مجاني/مدفوع) وبيئة البناء اتحسم

### تعديلات الإصدار 1.1
- [ ] C1: الاستعادة بدل افتراض الاستمرار + بدون اعتماد على applicationWillTerminate
- [ ] C2: Universal Link + زر يدوي دائم
- [ ] C3: last_received_point ≠ last_distance_anchor
- [ ] C4: NFC خارج المصنّف
- [ ] C5: HealthKit في الآخر + health_ops
- [ ] C6: بوابة الجدوى قبل أي شراء

### المنطق
- [ ] الثلاث آلات منفصلة
- [ ] State machine نقية بترجع Commands
- [ ] كل threshold في Config
- [ ] Unit + Replay tests

### البيانات
- [ ] events append-only
- [ ] segments منفصلة عن trips
- [ ] gps_points بالمرفوض والمقبول
- [ ] UTC في كل الأوقات
- [ ] الإجماليات مشتقة

### الحساب
- [ ] فلتر GPS بالترتيب (7.2)
- [ ] stationary gate
- [ ] jitter threshold
- [ ] قص الذيل
- [ ] moving vs total duration

### iOS
- [ ] Info.plist كامل
- [ ] Background location + pausesAutomatically = false
- [ ] SLC + Regions
- [ ] NativeEventBuffer
- [ ] Reconciliation من history

### Health
- [ ] لا كتابة خطوات
- [ ] SyncIdentifier + UUID محفوظ
- [ ] حذف/إعادة كتابة عند التصحيح

### الاختبار
- [ ] كل السيناريوهات S1–S16
- [ ] Field tests (13.4)
- [ ] Confusion matrix
- [ ] قياس البطارية

---

القرار المعتمد (الإصدار 1.1): التنفيذ يبدأ بإثبات البناء والتثبيت والوصول للحساسات على جهاز حقيقي، ثم تسجيل البيانات الخام وتحليلها، وبعدها بس نفعّل التصنيف التلقائي وإدارة الرحلات وHealthKit.

**NFC يؤكد نية البداية (والزر اليدوي متاح دايمًا) — Core Motion ومعه الخطوات والسرعة يصنّفوا — GPS المفلتر يحسب المسافة — آلة الحالات تدير التوقف والنسيان والفجوات — وأي حاجة مش مؤكدة تروح للمراجعة بدل ما تتضاف للإجمالي.**
