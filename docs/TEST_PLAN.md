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
