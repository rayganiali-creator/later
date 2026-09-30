# Build & release

## Prerequisites
Flutter 3.47.x, JDK 17+ (21 used in CI), Android SDK 36 with build-tools. `flutter doctor` must be green for Android.

## Test build (installable, QA tools on)
```
flutter build apk --release --flavor qa --split-per-abi --dart-define=LATER_PRO_SIGNING_KEY=<any string>
```
Package id `app.baadan.later.qa` (installs beside the store app). CI publishes it as a GitHub pre-release on every push.

## Signing (store)
1. Create the upload key once (keep it **outside** git and back it up — losing it means you cannot update the app):
   `keytool -genkeypair -v -keystore ~/later-release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias later`
2. Create `android/key.properties` (git-ignored):
```
storeFile=/home/you/later-release.jks
storePassword=...
keyAlias=later
keyPassword=...
```
   or export `LATER_KEYSTORE_FILE / LATER_KEYSTORE_PASSWORD / LATER_KEY_ALIAS / LATER_KEY_PASSWORD` in CI.
3. Build (Gradle refuses a store release without signing):
```
flutter build appbundle --release --flavor store \
  --dart-define=LATER_PRO_SIGNING_KEY=<long random secret, keep stable across releases> \
  --dart-define=BAZAAR_RSA_KEY=<public key from Bazaar developer panel>
flutter build apk --release --flavor store   # if the market wants an APK
```
Outputs: `build/app/outputs/bundle/storeRelease/app-store-release.aab`, `build/app/outputs/flutter-apk/app-store-release.apk`.
R8 minification + resource shrinking are on.

## Signed store build from GitHub (no local setup)
Actions → **Release (signed store build)** → Run workflow. It needs these repository secrets
(the keystore is stored as base64, never in git): `LATER_KEYSTORE_BASE64` (`base64 -w0 later-release.jks`),
`LATER_KEYSTORE_PASSWORD`, `LATER_KEY_ALIAS`, `LATER_KEY_PASSWORD`, `LATER_PRO_SIGNING_KEY`, and `BAZAAR_RSA_KEY`.
`BAZAAR_RSA_KEY` is shown by Bazaar only after the first upload: run once without it (purchases are off in that build), upload, copy the key from the panel, add the secret, run again and upload the new build.
It runs analyze + tests, builds the AAB and APK, checks the signature and that there is no INTERNET permission,
and attaches both files to the run (private, 14 days).

## Versioning
Edit `version:` in `pubspec.yaml` (`1.0.0+1` = versionName+versionCode). versionCode must increase for every upload.

## Changing prices / plans
`lib/core/config/pro_plans.dart` (price + duration + market SKU). Create matching **consumable** products in Bazaar: `later_pro_1m`, `later_pro_3m`, `later_pro_6m`.

## Changing legal texts
`assets/legal/{terms,privacy}_{fa,en}.txt`; bump `AppConfig.termsVersion / privacyVersion` to force re-acceptance. **Have the texts reviewed by a lawyer and add a real support contact (`AppConfig.supportEmail`) before publishing.**

## Before every release
`flutter analyze && flutter test`, CI green, install the QA APK on real devices and walk through `docs/TEST_PLAN.md`.
