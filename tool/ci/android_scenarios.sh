#!/usr/bin/env bash
# adb-driven scenarios run on an emulator (see .github/workflows/emulator.yml).
# Prints a plain-text report; exits non-zero only on hard failures. Findings that
# depend on OS/OEM behaviour are reported, not asserted.
set -u
PKG=${PKG:-app.baadan.later.qa}
REPORT=${REPORT:-scenario-report.txt}
exec > >(tee "$REPORT") 2>&1
FAIL=0
ok()   { echo "PASS  $*"; }
bad()  { echo "FAIL  $*"; FAIL=1; }
info() { echo "INFO  $*"; }

alarms() { adb shell dumpsys alarm | grep -c "$PKG" || true; }
ui_has() { adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; adb shell cat /sdcard/ui.xml | grep -q "$1"; }

echo "== device: $(adb shell getprop ro.product.model) / Android $(adb shell getprop ro.build.version.release) (API $(adb shell getprop ro.build.version.sdk))"

# ------------------------------------------------------------------ permissions
echo "== Declared permissions (release-relevant)"
adb shell dumpsys package "$PKG" | grep -E "android.permission\.(POST_NOTIFICATIONS|SCHEDULE_EXACT_ALARM|RECEIVE_BOOT_COMPLETED|INTERNET)" | sort -u

# ------------------------------------------------------------------ share sheet
echo "== Share sheet: SEND text/plain resolves to the app"
if adb shell cmd package query-activities --brief -a android.intent.action.SEND -t text/plain | grep -q "$PKG"; then
  ok "app listed as SEND text/plain target"
else
  bad "app not a SEND target"
fi
echo "== Launcher shortcuts / widgets registered"
adb shell cmd appwidget list 2>/dev/null | grep -q "$PKG" && ok "app widgets registered" || info "appwidget list unavailable/empty"

# ------------------------------------------------------------ notification alarms
echo "== Alarms scheduled by the app right now: $(alarms)"
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null || true

echo "== Force-stop"
adb shell am force-stop "$PKG"; sleep 2
info "alarms after force-stop: $(alarms)  (Android clears alarms of force-stopped apps: expected 0)"

echo "== Timezone change"
adb shell settings put global auto_time_zone 0 2>/dev/null
adb shell service call alarm 3 s16 Asia/Tehran >/dev/null 2>&1 || adb shell cmd time_zone_detector set_manual_time_zone Asia/Tehran 2>/dev/null || true
info "timezone now: $(adb shell getprop persist.sys.timezone)"

echo "== Reboot"
adb reboot; adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 3; done
sleep 20
info "alarms after reboot (stopped app + reboot): $(alarms)"
echo "== Launching app after reboot re-syncs reminders"
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 8
info "alarms after re-launch: $(alarms)"

echo "== Crash check"
if adb logcat -d | grep -E "FATAL EXCEPTION" | grep -q "$PKG\|later"; then bad "fatal exception in logcat"; else ok "no fatal exceptions in logcat"; fi

exit $FAIL
