#!/usr/bin/env bash
# 在 GitHub Actions runner（x86_64，自带 Android SDK）上编译 WebView 壳子 APK
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
OUT="$ROOT/out"
rm -rf "$OUT"; mkdir -p "$OUT/obj" "$OUT/dex" "$OUT/src"

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}}"
BT=$(ls -d "$SDK"/build-tools/*/ 2>/dev/null | sort -V | tail -1); BT="${BT%/}"
PLATFORM=$(ls -d "$SDK"/platforms/android-*/android.jar 2>/dev/null | sort -V | tail -1)
[ -n "$BT" ] && [ -n "$PLATFORM" ] || { echo "找不到 Android SDK"; exit 1; }
URL="$(tr -d '\r\n' < url.txt 2>/dev/null || true)"
[ -n "$URL" ] || URL="https://example.com"
echo "SDK=$SDK"; echo "BT=$BT"; echo "PLATFORM=$PLATFORM"; echo "URL=$URL"

echo "== 注入网址并 javac =="
sed "s|__APP_URL__|$URL|g" src/com/mimichong/game/MainActivity.java > "$OUT/src/MainActivity.java"
javac -source 8 -target 8 -nowarn -classpath "$PLATFORM" -d "$OUT/obj" "$OUT/src/MainActivity.java"

echo "== d8 =="
"$BT/d8" --release --min-api 24 --lib "$PLATFORM" --output "$OUT/dex" "$OUT/obj/com/mimichong/game/"*.class

echo "== aapt2 =="
"$BT/aapt2" compile --dir res -o "$OUT/res.zip"
"$BT/aapt2" link -o "$OUT/base.apk" -I "$PLATFORM" \
  --manifest AndroidManifest.xml --min-sdk-version 24 --target-sdk-version 34 \
  "$OUT/res.zip"

echo "== 打包 dex =="
python3 - "$OUT" <<'PY'
import sys, zipfile, os
out = sys.argv[1]
zin = zipfile.ZipFile(os.path.join(out, "base.apk"), "r")
zout = zipfile.ZipFile(os.path.join(out, "withdex.apk"), "w", zipfile.ZIP_DEFLATED)
for item in zin.infolist():
    zout.writestr(item, zin.read(item.filename))
zin.close()
with open(os.path.join(out, "dex", "classes.dex"), "rb") as f:
    zout.writestr("classes.dex", f.read())
zout.close()
print("packed ok")
PY

echo "== zipalign =="
"$BT/zipalign" -f 4 "$OUT/withdex.apk" "$OUT/aligned.apk"

echo "== 签名 =="
keytool -genkeypair -keystore "$OUT/keystore.jks" -alias app -keyalg RSA -keysize 2048 \
  -validity 10000 -storepass mimichong -keypass mimichong \
  -dname "CN=mimichong,OU=game,O=mimichong,L=CN,ST=CN,C=CN" 2>/dev/null
"$BT/apksigner" sign --ks "$OUT/keystore.jks" --ks-pass pass:mimichong --key-pass pass:mimichong \
  --out "$ROOT/app.apk" "$OUT/aligned.apk"
"$BT/apksigner" verify "$ROOT/app.apk" && ls -l "$ROOT/app.apk"
echo "APK OK"
