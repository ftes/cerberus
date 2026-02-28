#!/usr/bin/env bash
set -euo pipefail

GECKODRIVER_PORT="${CERBERUS_GECKODRIVER_PORT:-4545}"

usage() {
  cat <<'USAGE'
Usage: bin/check_gecko_bidi_ready.sh [--port PORT]

Checks Firefox WebDriver BiDi readiness for Cerberus:
- verifies Firefox and GeckoDriver are available,
- starts local GeckoDriver,
- performs a WebDriver session handshake with `webSocketUrl: true`.

Environment:
  FIREFOX      Required path to Firefox binary.
  GECKODRIVER  Required path to GeckoDriver binary.

Options:
  --port PORT  Local GeckoDriver HTTP port (default: 4545).
  -h, --help   Show this help.
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)
      [[ $# -ge 2 ]] || fail "missing value for --port"
      GECKODRIVER_PORT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[[ -n "${FIREFOX:-}" ]] || fail "FIREFOX is not set"
[[ -x "$FIREFOX" ]] || fail "FIREFOX is not executable: $FIREFOX"
[[ -n "${GECKODRIVER:-}" ]] || fail "GECKODRIVER is not set"
[[ -x "$GECKODRIVER" ]] || fail "GECKODRIVER is not executable: $GECKODRIVER"

LOG_FILE="tmp/geckodriver.log"
mkdir -p "$(dirname "$LOG_FILE")"

"$GECKODRIVER" --port "$GECKODRIVER_PORT" >"$LOG_FILE" 2>&1 &
DRIVER_PID=$!
cleanup() {
  kill "$DRIVER_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

ready=0
for _ in $(seq 1 100); do
  if curl -fsS "http://127.0.0.1:${GECKODRIVER_PORT}/status" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.05
done
[[ "$ready" -eq 1 ]] || fail "geckodriver did not become ready on port $GECKODRIVER_PORT"

payload="$(jq -n --arg binary "$FIREFOX" '{
  capabilities: {
    alwaysMatch: {
      browserName: "firefox",
      webSocketUrl: true,
      "moz:firefoxOptions": {
        binary: $binary,
        args: ["-headless"]
      }
    }
  }
}')"

response="$(
  curl -sS \
    -X POST \
    "http://127.0.0.1:${GECKODRIVER_PORT}/session" \
    -H "Content-Type: application/json" \
    -d "$payload"
)"

error_code="$(jq -r '.value.error // empty' <<<"$response")"
if [[ -n "$error_code" ]]; then
  error_message="$(jq -r '.value.message // "unknown session creation error"' <<<"$response")"
  fail "$error_message"
fi

session_id="$(jq -r '.value.sessionId // empty' <<<"$response")"
web_socket_url="$(jq -r '.value.capabilities.webSocketUrl // empty' <<<"$response")"

[[ -n "$session_id" ]] || fail "session creation succeeded but sessionId is empty: $response"
[[ -n "$web_socket_url" ]] || fail "session created without capabilities.webSocketUrl: $response"

curl -sS -X DELETE "http://127.0.0.1:${GECKODRIVER_PORT}/session/${session_id}" >/dev/null || true

echo "Firefox BiDi readiness OK"
echo "firefox_binary=$FIREFOX"
echo "geckodriver_binary=$GECKODRIVER"
echo "webSocketUrl=$web_socket_url"
