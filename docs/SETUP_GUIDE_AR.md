# دليل تجهيز بيئة العمل — BikeTrack (خطوة بخطوة)

الأدوار: إنت صاحب القرار وبتجرب على الآيفون — ChatGPT وPerplexity للتخطيط والمراجعة — Antigravity المنفّذ الأساسي — Codex للمراجعة والاختبارات والمهام المستقلة.

---

## الخطوة 1 — افحص الأدوات (PowerShell)

```powershell
flutter --version
dart --version
git --version
flutter doctor -v
```

- طبيعي إن `flutter doctor` على Windows ما يظهرش أي حاجة عن iOS/Xcode؛ ده مش خطأ.
- المهم: Flutter وDart وGit شغالين.
- Antigravity: تأكد إن الإصدار **1.20.5 أو أحدث** (من الإصدار ده بيقرأ `AGENTS.md`).
- Codex: متثبت (CLI أو إضافة الـ IDE) ومسجل دخول.

ابعت النتائج لو ظهر أي خطأ أحمر.

---

## الخطوة 2 — أنشئ المشروع

مسار من غير مسافات ولا حروف عربي:

```powershell
mkdir C:\dev -Force
cd C:\dev
flutter create --org com.mohamedalaa --project-name biketrack --platforms ios BikeTrack
cd BikeTrack
git init
git branch -M main
```

---

## الخطوة 3 — حط ملفات الـ Agents

1. فك ضغط `BikeTrack-starter.zip`.
2. انسخ **محتوى** مجلد `BikeTrack-starter` (مش المجلد نفسه) جوه `C:\dev\BikeTrack`، ووافق على استبدال `README.md`.
3. لازم يبقى عندك:

```
BikeTrack/
├── AGENTS.md
├── README.md
├── .agents/rules/dart-domain.md
├── .agents/rules/swift-ios.md
├── .github/pull_request_template.md
├── docs/ (PROJECT_BRIEF, ARCHITECTURE, DECISIONS, ROADMAP, STATUS, TASKS, ENGINEERING_PLAN, SETUP_GUIDE_AR)
├── lib/  test/  ios/  pubspec.yaml ...
```

> ملاحظة: مجلد `.agents` بيبدأ بنقطة؛ لو مش ظاهر في File Explorer فعّل View → Hidden items.

---

## الخطوة 4 — تأكد إن المشروع سليم

```powershell
flutter pub get
flutter analyze
flutter test
```

لازم الـ test الافتراضي يعدّي.

---

## الخطوة 5 — أول commit و GitHub

```powershell
git add .
git commit -m "S0: Flutter project + agent workspace files"
```

- اعمل Repository **Private** على GitHub باسم `BikeTrack` (من غير README عشان ما يحصلش تعارض).

```powershell
git remote add origin https://github.com/<username>/BikeTrack.git
git push -u origin main
```

- من إعدادات الريبو: Branch protection على `main` (Require pull request) — اختياري بس مفيد عشان ما حدش يكتب على main مباشرة.

---

## الخطوة 6 — إعداد Antigravity

1. افتح `C:\dev\BikeTrack` كـ Project.
2. إعدادات المشروع (Windows):
   - Terminal execution policy: خليه يطلب موافقة (مش تشغيل تلقائي) في البداية.
   - Outside of folder file access: **Always Ask** أو **Always Deny**.
3. افتح Customizations → Rules وتأكد إن القاعدتين `dart-domain` و`swift-ios` ظاهرين (لو مش ظاهرين يبقى الـ frontmatter فيه مشكلة).
4. للمهام الكبيرة استخدم **New Worktree mode** عشان كل محادثة تشتغل في نسخة منفصلة وما تلخبطش فولدرك.

---

## الخطوة 7 — اختبار فهم الـ Agents (من غير تعديل كود)

### Antigravity — مهمة T-001
```
Task T-001 from docs/TASKS.md. Read-only: do not create or edit any file.
Read AGENTS.md, docs/STATUS.md, docs/TASKS.md, docs/DECISIONS.md only.
Reply with:
1) The 5 most important hard rules.
2) D-007, D-009, D-010 in your own words.
3) The exact format/analyze/test commands.
4) What you cannot do on this Windows machine.
```

### Codex — مهمة T-002
نفس البرومبت بالظبط مع تغيير الرقم لـ T-002.

**القبول:** الاتنين يطلّعوا نفس القواعد، ومحدش فيهم عدّل أي ملف (`git status` لازم يبقى نظيف). لو حد فيهم فهم غلط، نعدّل `AGENTS.md` قبل ما نكمل.

---

## الخطوة 8 — أول مهمة كود حقيقية صغيرة

### Antigravity — T-003
```
Execute T-003 from docs/TASKS.md exactly.
Create branch task/T-003-domain-geo.
Only touch lib/domain/** and test/domain/**.
Follow .agents/rules/dart-domain.md.
Run: dart format . ; flutter analyze ; flutter test
Update docs/STATUS.md (max 5 lines) and end with the Report format from AGENTS.md.
```
بعدها: `git push -u origin task/T-003-domain-geo` واعمل Pull Request.

### Codex — T-004 (مراجعة)
```
Task T-004: review branch task/T-003-domain-geo against AGENTS.md and D-003.
Do not modify files. Run flutter test and flutter analyze.
Report: issues by severity (blocker/major/minor), missing tests, and whether it meets T-003 acceptance criteria.
```

إنت تقرا التقريرين وتعمل Merge لو كله تمام.

---

## الخطوة 9 — دورة العمل اليومية (ثابتة)

1. **أنا/ChatGPT**: نكتب المهمة الجديدة في `docs/TASKS.md` بالقالب (الملفات المسموحة + معيار القبول).
2. **Antigravity**: ينفذ في branch خاص.
3. **Codex**: يراجع أو يكتب tests إضافية (في branch تاني أو كتعليقات).
4. **إنت**: تقرا التقرير → Merge → تحدّث `STATUS.md` لو الـ Agent ما حدثهوش.
5. لو فيه قرار معماري جديد → يتكتب في `DECISIONS.md` كـ Proposed، وإنت توافق قبل التنفيذ.

**ممنوع:** إن الاتنين يشتغلوا على نفس الملفات في نفس الوقت. التوازي مسموح بس لو "Allowed files" مختلفة تمامًا وكل واحد في branch أو worktree لوحده.

---

## الخطوة 10 — قرار بوابة M0 (قبل أي فلوس)

- بناء وتثبيت تطبيق على الآيفون **بالحساب المجاني** محتاج Xcode على macOS (جلسة Mac مؤجرة قصيرة مثلًا). خدمات CI زي Codemagic وTestFlight غالبًا محتاجة عضوية Apple Developer المدفوعة — هنتأكد من ده في M0 مش هنفترضه.
- لما توصل هنا، قولي وأنا أكتبلك مهام M0 (التطبيق التجريبي) في `TASKS.md` جاهزة للتنفيذ.

---

## ليه الترتيب ده بيوفّر توكنز

- `AGENTS.md` قصير (حوالي 2.6 ألف حرف) وبيتحمّل دايمًا.
- قواعد Swift وDart بتتحمّل **بس** لما الـ Agent يلمس ملفات من نوعها (trigger: glob).
- الخطة الكاملة (`ENGINEERING_PLAN.md`) ما بتتقريش إلا القسم اللي المهمة بتشاور عليه (§).
- `STATUS.md` أقل من 15 سطر وبيتكتب فوقه، مش بيتراكم.
