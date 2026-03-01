#!/usr/bin/env bash
set -euo pipefail

set -a
source .env
set +a

flutter run -d "iPhone 16e" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"