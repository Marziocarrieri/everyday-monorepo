#!/usr/bin/env bash
set -euo pipefail

set -a
source .env
set +a

flutter run -d "Pixel 9a" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"q