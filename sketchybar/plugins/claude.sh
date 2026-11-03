#!/bin/bash

# Claude 5-hour session usage: "<% left> · <time to reset>", colored by % left.
#
# Rules this script keeps:
#   - Reads the access token from the Keychain only. Never refreshes it.
#     A 401 means "token expired": show cached value in gray and wait for
#     Claude Code to refresh it.
#   - Never prints, logs or stores the token. It goes to curl via stdin
#     (-H @-), so it is not visible in `ps` either.
#   - Cache holds numbers only: utilization, resets_at, fetched_at.

CACHE_DIR="$HOME/.cache/sketchybar"
CACHE="$CACHE_DIR/claude_usage.json"
NAME="${NAME:-claude}"

GREEN=0xffaad94c
ORANGE=0xffffb454   # same orange as mode.sh
RED=0xfff07178
GRAY=0x80ffffff     # same dim white as mode.sh

# Pull "utilization<TAB>resets_at" out of a usage response.
# Supports .five_hour.{utilization,resets_at} and a .limits[] array.
parse() {
  jq -r '
    # Seen 2026-11-04: both .five_hour and .limits[] are present.
    # limits[] entries look like {kind:"session", percent:39, resets_at:...}.
    def fh:
      if (.five_hour.utilization? // null) != null then .five_hour
      else ((.limits // []) | map(select(.kind == "session"))
            | first // empty
            | {utilization: .percent, resets_at: .resets_at})
      end;
    fh | select(.utilization != null and .resets_at != null)
       | "\(.utilization)\t\(.resets_at)"
  ' 2>/dev/null
}

fetch() {
  local token
  token="$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
           | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)"
  [ -n "$token" ] || return 1

  local body status
  body="$(printf 'Authorization: Bearer %s\n' "$token" \
    | curl -sS --max-time 5 -w '\n%{http_code}' \
        -H @- \
        -H 'anthropic-beta: oauth-2025-04-20' \
        -H 'Accept: application/json' \
        https://api.anthropic.com/api/oauth/usage 2>/dev/null)"
  unset token
  status="${body##*$'\n'}"
  body="${body%$'\n'*}"
  [ "$status" = "200" ] || return 1

  local parsed
  parsed="$(printf '%s' "$body" | parse)"
  [ -n "$parsed" ] || return 1

  mkdir -p "$CACHE_DIR"
  printf '%s\n' "$parsed" | jq -R --argjson now "$(date +%s)" '
      split("\t") | {utilization: (.[0] | tonumber), resets_at: .[1], fetched_at: $now}
    ' > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
}

# ISO 8601 (with optional fractional seconds / offset) -> epoch seconds
to_epoch() {
  jq -rn --arg t "$1" '
    $t | sub("\\.[0-9]+"; "") | sub("(\\+00:00|\\+0000)$"; "Z") | fromdateiso8601
  ' 2>/dev/null
}

render() {
  local fresh="$1"
  if [ ! -s "$CACHE" ]; then
    sketchybar --set "$NAME" label="--" label.color="$GRAY" icon.color="$GRAY"
    return
  fi

  local util resets now reset_epoch left secs color time_str
  util="$(jq -r '.utilization' "$CACHE")"
  resets="$(jq -r '.resets_at' "$CACHE")"
  now="$(date +%s)"
  reset_epoch="$(to_epoch "$resets")"

  if [ -z "$reset_epoch" ] || [ "$reset_epoch" -le "$now" ]; then
    # Window already reset since we last saw it.
    sketchybar --set "$NAME" label="100%" label.color="$GRAY" icon.color="$GRAY"
    return
  fi

  left="$(jq -rn --argjson u "$util" '(100 - $u) | if . < 0 then 0 else . end | round')"
  secs=$(( reset_epoch - now ))
  if [ "$secs" -ge 3600 ]; then
    time_str="$(( secs / 3600 ))h$(( secs % 3600 / 60 ))m"
  else
    time_str="$(( secs / 60 ))m"
  fi

  if [ "$fresh" != "1" ]; then
    color="$GRAY"
  elif [ "$left" -gt 50 ]; then
    color="$GREEN"
  elif [ "$left" -ge 20 ]; then
    color="$ORANGE"
  else
    color="$RED"
  fi

  sketchybar --set "$NAME" label="${left}% · ${time_str}" label.color="$color" icon.color="$color"
}

# Click to refresh: ignore clicks within 30s of the last successful fetch,
# so repeated clicks don't hammer an endpoint whose rate limits we don't know.
if [ "$CLAUDE_USAGE_CLICK" = "1" ] && [ -s "$CACHE" ]; then
  last="$(jq -r '.fetched_at // 0' "$CACHE" 2>/dev/null)"
  if [ $(( $(date +%s) - ${last:-0} )) -lt 30 ]; then
    render 1
    exit 0
  fi
fi

# CLAUDE_USAGE_OFFLINE=1 skips the network (for testing colors from the cache).
if [ "$CLAUDE_USAGE_OFFLINE" != "1" ] && fetch; then
  render 1
else
  render 0
fi
