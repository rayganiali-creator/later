# Manual test plan (QA build `app.baadan.later.qa`)

Install the QA APK from the GitHub pre-release. Settings → bottom: **ابزار تست**.

1. **First run:** onboarding (5 pages, skip works) → terms/privacy gate (cannot continue unchecked) → Home.
2. **Add:** FAB → type only a title → keyboard Done. Then add one with date, time, reminder, priority, duration, URL, tags, note.
3. **Reminder:** QA tools → "اعلان تا ۳۰ ثانیه" (grant permission) → lock phone → notification arrives. Repeat with app swiped away, after **force-stop** (expected: not delivered until app opened), after **reboot** (expected: delivered for reminders scheduled through the plugin), after changing timezone and the clock.
4. **Notification buttons:** "انجام شد" / "فردا" from the shade without opening the app.
5. **Share:** Chrome → ⋮ → Share → بعداً. Also select text in any app → بعداً.
6. **Widgets:** add both widgets; +/🎯 buttons; list widget shows "Pro" hint on free; shows items after simulating Pro.
7. **Shortcuts:** long-press the launcher icon → Add / Pick / Search.
8. **Pro:** simulate 1-day plan → features unlock; advance clock 2 days → Pro off, data intact; simulate 1 month, advance 15 days, buy 3 months → expiry = 15 + 90 days (Pro screen shows remaining days); expired → buy → starts from purchase time.
9. **Backup:** QA → add 100/1000/5000 items → Backup → export → clear app data (or reset) → restore → counts and Pro status identical. Try a hand-edited file, a truncated file, a non-.later file: friendly error, data untouched.
10. **Themes:** Light / Dark / System; accent (Pro); font size 100% → 200%; TalkBack over Home, list, add sheet.
11. **Reset:** requires typing the word; Pro remains.
12. **Performance:** 5000 items → scrolling, search, cold start.

## New sections (v2)

13. **Home vs list:** Home is a dashboard (roulette card, counters, inbox, shelves) and never lists items; the «بعداً» tab is the full list with type/inbox chips.
14. **Inbox / share:** share a YouTube link and a shop link from Chrome → «کجا نگهش دارم؟» sheet; dismiss → item is in the inbox. On the inbox screen use each triage chip; undo works. Free: no suggestion; QA → simulate Pro → suggestion appears and is never applied without a tap.
15. **Shelves:** بعداً بخون / ببین / بخر / ایده‌ها: add with the type chips, change stage, finish (history), wishlist price + «هنوز می‌خوایش؟» (QA: advance 31 days). Free: no stats/collections/target price (Pro sheet opens).
16. **Roulette:** pick, another, later (snooze), start; Free: filters open the Pro sheet; Pro: time/priority/energy/category + history.
17. **People:** add from contacts (system picker, no permission prompt) and by name; «بعداً به X پیام بده» with a date → notification; open contact. Pro: history, follow-up, groups, «باید سر بزنی».
18. **Time capsule / message:** create with a date tomorrow (QA: sample button), text hidden while locked (also in search), advance 2 days → notification + reveal screen. Free limit = 2 each; Pro: attachments ≤2 MB, repeat yearly.
19. **Backup v2:** export with all sections (incl. attachments), reset, restore; also restore an old v1 backup file.
20. **Pro screen:** every plan lists all 12 features with descriptions; prices unchanged; stacking note.

## New modules (v1.1)

21. **Apps / podcasts / courses / games:** add one of each (type chips in the add sheet). Check the shelf colours, stage chips, history tab and the status button on each row. Apps: «آیا هنوز به این برنامه نیاز دارم؟» (4 answers); QA → advance 31 days → the stale review shows the 4-answer variant. Podcasts: progress slider + position, «باقی مانده», continue button, smart queue (Pro). Courses: goal text (free), date + weekly target + sessions + streak (Pro). Games: grid with covers, «یه بازی انتخاب کن» (free: random; Pro: time / genre / priority / status).
22. **Pictures:** add from gallery and from the camera (no permission prompt expected). Free: one picture; the second asks for Pro. Pro: up to 8, choose the main one, swipe + zoom, delete. A very large photo (30 MB+) shows the "too large" message; a non-image file shows "not a valid picture". Pictures show as thumbnails in lists/search/home, large in the detail sheet. Back up, reset, restore: pictures and covers are intact.
23. **Widgets (small / medium / large + Pro list):** add each from the launcher. Check light and dark mode, the counters, the suggestion text (changes with the time of day and your data), ＋ (opens the quick-save sheet and returns to the launcher after saving), 🎯 (roulette), 📥 (inbox), ⟳ (refresh), tapping the suggestion (opens that item). Add / delete / complete an item in the app → the widget changes; restore a backup → the widget changes; reboot the phone → the widgets still show the last data. Known limit: after midnight the "today" number shows «—» until the app is opened (Android does not let widgets run app code).
24. **Notifications / reboot / Android 13+ / offline / timezone / share sheet:** repeat scenarios 3, 5 and 12 above on the new build (including a reminder on a podcast or course).
