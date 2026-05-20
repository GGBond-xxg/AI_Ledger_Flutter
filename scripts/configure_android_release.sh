#!/usr/bin/env bash
set -euo pipefail

manifest="android/app/src/main/AndroidManifest.xml"
if [ -f "$manifest" ]; then
  python3 - <<'PY'
from pathlib import Path
import re
p = Path('android/app/src/main/AndroidManifest.xml')
s = p.read_text()
s = re.sub(r'android:label="[^"]*"', 'android:label="@string/app_name"', s)
if 'android.permission.INTERNET' not in s:
    s = re.sub(r'<manifest([^>]*)>', r'<manifest\1>\n    <uses-permission android:name="android.permission.INTERNET" />', s, count=1)
p.write_text(s)
PY
fi

mkdir -p android/app/src/main/res/values android/app/src/main/res/values-zh
cat > android/app/src/main/res/values/strings.xml <<'XML'
<resources>
    <string name="app_name">Ledger</string>
</resources>
XML

cat > android/app/src/main/res/values-zh/strings.xml <<'XML'
<resources>
    <string name="app_name">记账</string>
</resources>
XML

echo "Android label resources have been configured."
echo "Please verify applicationId/namespace is com.ggbong.ledger in android/app/build.gradle or build.gradle.kts."
