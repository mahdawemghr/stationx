#!/usr/bin/env bash
# Runs the app against the Supabase project in env/supabase.json (plain `flutter run` uses the built-in default). Usage: scripts/run.sh [extra flutter run args, e.g. -d <device>]
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -f env/supabase.json ]; then
  echo "env/supabase.json is missing. Copy env/supabase.example.json to env/supabase.json and fill in the project URL and PUBLISHABLE key." >&2
  exit 1
fi
exec flutter run --dart-define-from-file=env/supabase.json "$@"
