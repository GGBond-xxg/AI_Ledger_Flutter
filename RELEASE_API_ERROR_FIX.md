# v20 - Release API and friendly error fixes

Changes:

1. API base URL is normalized before saving/requesting.
   - `ledger.example.com/` becomes `https://ledger.example.com`
   - `https://ledger.example.com/api/health` becomes `https://ledger.example.com`
   - non-local `http://` is upgraded to `https://`
   - localhost / 127.0.0.1 keep `http://` for local testing

2. Raw network errors are converted into user-friendly messages.

3. When API URL or API Token is not configured, the home page does not show a red error banner. It uses local valuation first.

4. If Android release builds cannot access network, check `android/app/src/main/AndroidManifest.xml` and add:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

Place these under `<manifest>` and before `<application>`.

5. Keep API URL in Settings as domain only, for example:

```text
https://ledger.wweh.dpdns.org
```

Do not fill:

```text
https://ledger.wweh.dpdns.org/api/health
```
