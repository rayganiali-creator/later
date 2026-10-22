# Security & privacy review

Scope reviewed: source in this repository (Dart + Kotlin + manifest). Not a third-party penetration test.

| Area | Finding / control |
|---|---|
| Storage | Items live in the app-private SQLite DB (sandboxed by Android). `allowBackup=false` + `data_extraction_rules` exclude cloud/device-transfer copies. Pro state uses Android Keystore–wrapped storage + HMAC (device key). |
| Backup file | Not encrypted by design (user-portable). Documented in Privacy Policy. Integrity via SHA-256, strict validation, size/nesting caps, path traversal impossible (no paths read from file; ids regex-restricted), transactional restore, safety copy. Tested with corrupt, truncated, empty, future, oversized, hostile-nesting, wrong-type, duplicate-id, javascript: URL cases. |
| Deep links / intents | No custom URL scheme. Exported components: `MainActivity` (SEND text/plain, PROCESS_TEXT, launcher aliases). Only plain text accepted, ≤20 000 chars, quick actions whitelisted (`add/pick/search/open`), payload removed from the intent after use. Widgets/receivers `exported=false`. |
| Share sheet | Input treated as untrusted text; URL extracted then re-validated (http/https only). |
| Notifications | Payload is only `item:<id>`. Optional "hide text" mode uses generic text + private lock-screen visibility. Action ids whitelisted. |
| URL handling | `sanitizeUrl` rejects javascript:, file:, content:, intent:, data:. Links open with `LaunchMode.externalApplication`; no WebView anywhere. |
| Export | CSV cells starting with `= + - @ TAB` are neutralized (CSV/formula injection). |
| Logs | Release builds log only exception *types*; no titles/notes/URLs are ever logged. |
| Clipboard | Never read or written by the app. |
| Secrets | None in source. Signing keystore and passwords come from git-ignored `android/key.properties` or CI env. `LATER_PRO_SIGNING_KEY` and `BAZAAR_RSA_KEY` are `--dart-define` inputs. CI fails if a keystore/key.properties is tracked. |
| Permissions | POST_NOTIFICATIONS (runtime, in context), SCHEDULE_EXACT_ALARM (optional), RECEIVE_BOOT_COMPLETED, VIBRATE, Bazaar billing permission. **No INTERNET** in the store build (asserted in CI). No storage, contacts, location, mic, camera. |
| Pro anti-tamper | Clock high-water mark, HMAC-protected record, signed backup entitlement, tamper flag. **Inherent limit:** a local-first app cannot stop a rooted user / patched APK from granting themselves Pro. Server-side receipt verification (Bazaar REST API) is the only complete fix and is intentionally out of scope for a no-server app; the `PurchaseGateway` seam allows adding it later. Backup-carried Pro can be shared between users who share a backup file and the same build key — accepted trade-off so paying users don't lose Pro on reinstall (disable by building without `LATER_PRO_SIGNING_KEY`). |
| Reset | "Erase everything" requires typing a word; keeps the purchase entitlement. |
| Known residual risks | Unencrypted backup files; a debuggable/QA build exposes `run-as`; billing path unverified without a Bazaar account (see report). |
