#!/usr/bin/env bash
# Interactive helper: creates the Android UPLOAD keystore (outside the repo) and android/key.properties.
# Passwords are read silently and never echoed or printed. Run it yourself: bash scripts/make_release_keystore.sh
set -euo pipefail

command -v keytool >/dev/null || { echo "keytool not found (install a JDK 17)." >&2; exit 1; }
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
props="$repo/android/key.properties"

read -r -p "Keystore path [$HOME/keys/stationx-upload.jks]: " ks
ks="${ks:-$HOME/keys/stationx-upload.jks}"
ks="${ks/#\~/$HOME}"
case "$(cd "$(dirname "$ks")" 2>/dev/null && pwd)/" in
  "$repo"/*) echo "Refusing: keep the keystore OUTSIDE the repo." >&2; exit 1;;
esac
[ -e "$ks" ] && { echo "Refusing to overwrite existing keystore: $ks" >&2; exit 1; }
if [ -e "$props" ]; then
  read -r -p "$props already exists and will be replaced (old copy saved as key.properties.bak). Continue? [y/N] " a
  [ "${a:-N}" = y ] || [ "${a:-N}" = Y ] || { echo "Aborted."; exit 1; }
fi
read -r -p "Key alias [upload]: " alias_; alias_="${alias_:-upload}"
read -r -p "Your name or organisation (for the certificate) [StationX]: " cn; cn="${cn:-StationX}"

read -r -s -p "Keystore password (min 6 chars): " sp; echo
read -r -s -p "Repeat keystore password: " sp2; echo
[ "$sp" = "$sp2" ] && [ "${#sp}" -ge 6 ] || { echo "Passwords differ or too short." >&2; exit 1; }
read -r -s -p "Key password (Enter = same as keystore password): " kp; echo
kp="${kp:-$sp}"
[ "${#kp}" -ge 6 ] || { echo "Key password too short." >&2; exit 1; }

mkdir -p "$(dirname "$ks")"; chmod 700 "$(dirname "$ks")" 2>/dev/null || true
# Passwords go through environment variables, not the command line (not visible in `ps`).
SX_SP="$sp" SX_KP="$kp" keytool -genkeypair -v -keystore "$ks" -alias "$alias_" \
  -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=$cn" \
  -storepass:env SX_SP -keypass:env SX_KP
chmod 600 "$ks"

[ -e "$props" ] && cp -p "$props" "$props.bak"
umask 177
{
  echo "storePassword=$sp"
  echo "keyPassword=$kp"
  echo "keyAlias=$alias_"
  echo "storeFile=$ks"
} > "$props"
unset sp sp2 kp

cat <<MSG

==================================================================
  BACK UP NOW:  $ks
  and BOTH passwords (password manager + an offline copy).
  If you lose the keystore or passwords you cannot sign updates
  with this key. With Play App Signing you could ask Google to
  reset the upload key, but it is slow and not guaranteed.
  NEVER commit it: *.jks, *.keystore, key.properties are gitignored.
==================================================================
Wrote $props (mode 600).

Build:   flutter build appbundle --release --dart-define-from-file=env/supabase.json
Output:  build/app/outputs/bundle/release/app-release.aab
Verify an APK's signature (apk, not aab):
  flutter build apk --release --dart-define-from-file=env/supabase.json
  apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
  (apksigner is in \$ANDROID_HOME/build-tools/<version>/; for an .aab use: keytool -printcert -jarfile app-release.aab)
Compare the SHA-256 with: keytool -list -v -keystore "$ks" -alias "$alias_"
MSG
