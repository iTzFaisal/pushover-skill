#!/usr/bin/env bash

set -u

endpoint="https://api.pushover.net/1/messages.json"
message=""
title=""
device=""
priority="0"
sound=""
url=""
url_title=""
ttl=""
timestamp=""
retry=""
expire=""
callback=""
tags=""
confirm_emergency="0"

usage() {
  cat <<'EOF'
Usage: send_pushover.sh --message TEXT [options]

Options:
  --title TEXT
  --device NAME
  --priority -2|-1|0|1|2
  --sound NAME
  --url URL
  --url-title TEXT
  --ttl SECONDS
  --timestamp UNIX_TIMESTAMP
  --retry SECONDS       Required for priority 2; minimum 30
  --expire SECONDS      Required for priority 2; maximum 10800
  --callback URL        Optional priority-2 acknowledgement callback
  --tags TAGS           Optional priority-2 comma-separated tags
  --confirm-emergency   Required for priority 2
  --help

Environment:
  PUSHOVER_APP_TOKEN    Application API token for live sends
  PUSHOVER_USER_KEY     User or group key for live sends
  PUSHOVER_DRY_RUN=1    Print a request summary without making a request
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --message)
      [ "$#" -ge 2 ] || fail "--message requires a value"
      message="$2"
      shift 2
      ;;
    --title)
      [ "$#" -ge 2 ] || fail "--title requires a value"
      title="$2"
      shift 2
      ;;
    --device)
      [ "$#" -ge 2 ] || fail "--device requires a value"
      device="$2"
      shift 2
      ;;
    --priority)
      [ "$#" -ge 2 ] || fail "--priority requires a value"
      priority="$2"
      shift 2
      ;;
    --sound)
      [ "$#" -ge 2 ] || fail "--sound requires a value"
      sound="$2"
      shift 2
      ;;
    --url)
      [ "$#" -ge 2 ] || fail "--url requires a value"
      url="$2"
      shift 2
      ;;
    --url-title)
      [ "$#" -ge 2 ] || fail "--url-title requires a value"
      url_title="$2"
      shift 2
      ;;
    --ttl)
      [ "$#" -ge 2 ] || fail "--ttl requires a value"
      ttl="$2"
      shift 2
      ;;
    --timestamp)
      [ "$#" -ge 2 ] || fail "--timestamp requires a value"
      timestamp="$2"
      shift 2
      ;;
    --retry)
      [ "$#" -ge 2 ] || fail "--retry requires a value"
      retry="$2"
      shift 2
      ;;
    --expire)
      [ "$#" -ge 2 ] || fail "--expire requires a value"
      expire="$2"
      shift 2
      ;;
    --callback)
      [ "$#" -ge 2 ] || fail "--callback requires a value"
      callback="$2"
      shift 2
      ;;
    --tags)
      [ "$#" -ge 2 ] || fail "--tags requires a value"
      tags="$2"
      shift 2
      ;;
    --confirm-emergency)
      confirm_emergency="1"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[ -n "$message" ] || fail "--message is required"
case "$priority" in
  -2|-1|0|1|2) ;;
  *) fail "priority must be -2, -1, 0, 1, or 2" ;;
esac

if [ "$priority" = "2" ]; then
  [ "$confirm_emergency" = "1" ] || fail "priority 2 requires --confirm-emergency"
  [ -n "$retry" ] || fail "priority 2 requires --retry"
  [ -n "$expire" ] || fail "priority 2 requires --expire"
  case "$retry" in
    ''|*[!0-9]*) fail "retry must be an integer of at least 30 seconds" ;;
  esac
  case "$expire" in
    ''|*[!0-9]*) fail "expire must be an integer between 1 and 10800 seconds" ;;
  esac
  [ "$retry" -ge 30 ] || fail "retry must be at least 30 seconds"
  [ "$expire" -ge 1 ] && [ "$expire" -le 10800 ] || fail "expire must be between 1 and 10800 seconds"
  [ -z "$ttl" ] || fail "--ttl is not valid with priority 2"
else
  [ -z "$retry" ] || fail "--retry is only valid with priority 2"
  [ -z "$expire" ] || fail "--expire is only valid with priority 2"
  [ -z "$callback" ] || fail "--callback is only valid with priority 2"
  [ -z "$tags" ] || fail "--tags is only valid with priority 2"
fi

dry_run="${PUSHOVER_DRY_RUN:-0}"
if [ "$dry_run" = "1" ]; then
  printf 'Pushover dry run: no network request made.\n'
  printf 'POST %s\n' "$endpoint"
  printf 'Fields: token, user, message, priority=%s\n' "$priority"
  [ -n "$title" ] && printf 'Optional field: title\n'
  [ -n "$device" ] && printf 'Optional field: device\n'
  [ -n "$sound" ] && printf 'Optional field: sound\n'
  [ -n "$url" ] && printf 'Optional field: url\n'
  [ -n "$url_title" ] && printf 'Optional field: url_title\n'
  [ -n "$ttl" ] && printf 'Optional field: ttl\n'
  [ -n "$timestamp" ] && printf 'Optional field: timestamp\n'
  [ -n "$retry" ] && printf 'Optional field: retry\n'
  [ -n "$expire" ] && printf 'Optional field: expire\n'
  [ -n "$callback" ] && printf 'Optional field: callback\n'
  [ -n "$tags" ] && printf 'Optional field: tags\n'
  exit 0
fi

[ -n "${PUSHOVER_APP_TOKEN:-}" ] || fail "PUSHOVER_APP_TOKEN is not set"
[ -n "${PUSHOVER_USER_KEY:-}" ] || fail "PUSHOVER_USER_KEY is not set"

curl_args=(
  --silent
  --show-error
  --request POST
  --url "$endpoint"
  --data-urlencode "token=${PUSHOVER_APP_TOKEN}"
  --data-urlencode "user=${PUSHOVER_USER_KEY}"
  --data-urlencode "message=${message}"
  --data-urlencode "priority=${priority}"
)

[ -n "$title" ] && curl_args+=(--data-urlencode "title=${title}")
[ -n "$device" ] && curl_args+=(--data-urlencode "device=${device}")
[ -n "$sound" ] && curl_args+=(--data-urlencode "sound=${sound}")
[ -n "$url" ] && curl_args+=(--data-urlencode "url=${url}")
[ -n "$url_title" ] && curl_args+=(--data-urlencode "url_title=${url_title}")
[ -n "$ttl" ] && curl_args+=(--data-urlencode "ttl=${ttl}")
[ -n "$timestamp" ] && curl_args+=(--data-urlencode "timestamp=${timestamp}")
[ -n "$retry" ] && curl_args+=(--data-urlencode "retry=${retry}")
[ -n "$expire" ] && curl_args+=(--data-urlencode "expire=${expire}")
[ -n "$callback" ] && curl_args+=(--data-urlencode "callback=${callback}")
[ -n "$tags" ] && curl_args+=(--data-urlencode "tags=${tags}")

response_file="$(mktemp)"
cleanup() {
  rm -f "$response_file"
}
trap cleanup EXIT

http_code="$(curl "${curl_args[@]}" --output "$response_file" --write-out '%{http_code}')"
curl_status="$?"
response="$(cat "$response_file")"

if [ "$curl_status" -ne 0 ]; then
  printf 'Pushover request failed before a response was received.\n' >&2
  [ -n "$response" ] && printf '%s\n' "$response" >&2
  exit 1
fi

printf '%s\n' "$response"
if [ "$http_code" = "200" ] && [[ "$response" =~ \"status\"[[:space:]]*:[[:space:]]*1([^0-9]|$) ]]; then
  exit 0
fi

printf 'Pushover API rejected the request (HTTP %s).\n' "$http_code" >&2
exit 1
