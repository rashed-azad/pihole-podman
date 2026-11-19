#!/usr/bin/env bash
# Add curated blocklists via the Pi-hole v6 API, then rebuild gravity.
# Idempotent: skips any address already present. No sudo.
set -euo pipefail
cd "$(dirname "$0")"

API="http://localhost:8080/api"

if [ ! -f pihole.env ]; then
  echo "Missing pihole.env. Run: cp pihole.env.example pihole.env  (then set the password)"
  exit 1
fi
PASSWORD="$(grep -m1 '^FTLCONF_webserver_api_password=' pihole.env | cut -d= -f2-)"
[ -n "$PASSWORD" ] || { echo "No password found in pihole.env"; exit 1; }

# url|comment. All from the same maintainer (hagezi) so overlap is minimal
# and it's clear which list is responsible if something gets blocked.
LISTS=(
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/multi.txt|Hagezi Multi: ads, trackers, malware, phishing, scams"
  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/nsfw.txt|Hagezi NSFW: adult content"
)

SID=""
TMP="$(mktemp)"
cleanup() {
  rm -f "$TMP"
  [ -n "$SID" ] && curl -s -X DELETE "$API/auth" -H "X-FTL-SID: $SID" >/dev/null || true
}
trap cleanup EXIT

AUTH_RESPONSE="$(curl -s -X POST "$API/auth" -H "Content-Type: application/json" -d "{\"password\":\"$PASSWORD\"}")"
SID="$(grep -oP '"sid"\s*:\s*"[^"]+' <<<"$AUTH_RESPONSE" | sed 's/.*"//')"
if [ -z "$SID" ]; then
  echo "Login failed. If you changed the password in the Web UI since it was first set,"
  echo "pihole.env no longer matches it — update pihole.env or log in to confirm the current one."
  echo "Response: $AUTH_RESPONSE"
  exit 1
fi

EXISTING="$(curl -s "$API/lists" -H "X-FTL-SID: $SID")"

for entry in "${LISTS[@]}"; do
  url="${entry%%|*}"
  comment="${entry#*|}"
  if grep -qF "\"$url\"" <<<"$EXISTING"; then
    echo "Already present: $url"
    continue
  fi
  echo "Adding: $comment"
  # type=block must be a query param — the API rejects it inside the JSON body.
  status="$(curl -s -o "$TMP" -w '%{http_code}' -X POST "$API/lists?type=block" \
    -H "X-FTL-SID: $SID" -H "Content-Type: application/json" \
    -d "{\"address\":\"$url\",\"comment\":\"$comment\",\"enabled\":true}")"
  if [ "$status" != "201" ]; then
    echo "  warning: HTTP $status — $(cat "$TMP")"
  fi
done

echo "Rebuilding gravity..."
curl -s -X POST "$API/action/gravity" -H "X-FTL-SID: $SID" | tail -5
echo "Done. Web UI → Adlists to review, or Query Log to check for over-blocking."
