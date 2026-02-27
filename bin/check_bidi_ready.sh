#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${CERBERUS_BROWSER_TOOLS_DIR:-$ROOT_DIR/tmp/browser-tools}"
CHROMEDRIVER_PORT="${CERBERUS_CHROMEDRIVER_PORT:-9515}"
METADATA_URL="https://googlechromelabs.github.io/chrome-for-testing/latest-patch-versions-per-build-with-downloads.json"

INSTALL=0

usage() {
  cat <<'USAGE'
Usage: bin/check_bidi_ready.sh [--install] [--port PORT]

Checks WebDriver BiDi readiness for Cerberus:
- verifies Chrome and ChromeDriver versions,
- optionally installs a Chrome-matching ChromeDriver from Chrome for Testing,
- performs a WebDriver session handshake with `webSocketUrl: true`.

Environment:
  CHROME         Required path to Chrome binary.
  CHROMEDRIVER   Required path to ChromeDriver binary (unless --install is used).

Options:
  --install     Download and use a Chrome-matching ChromeDriver when needed.
  --port PORT   Local ChromeDriver HTTP port (default: 9515).
  -h, --help    Show this help.
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

platform() {
  case "$(uname -s):$(uname -m)" in
    Darwin:arm64) echo "mac-arm64" ;;
    Darwin:x86_64) echo "mac-x64" ;;
    Linux:x86_64) echo "linux64" ;;
    Linux:amd64) echo "linux64" ;;
    *) fail "unsupported platform $(uname -s):$(uname -m)" ;;
  esac
}

chrome_binary() {
  local configured="${CHROME:-}"

  if [[ -n "$configured" ]]; then
    [[ -x "$configured" ]] || fail "CHROME is not executable: $configured"
    echo "$configured"
    return
  fi

  fail "could not find a Chrome binary. Set CHROME."
}

version_of() {
  local binary="$1"
  "$binary" --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true
}

major_of() {
  local version="$1"
  echo "${version%%.*}"
}

build_of() {
  local version="$1"
  echo "${version%.*}"
}

download_matching_driver() {
  local chrome_version="$1"
  local platform_key="$2"
  local chrome_build
  local json
  local target_version
  local url
  local zip_file
  local unpack_dir
  local driver

  chrome_build="$(build_of "$chrome_version")"
  json="$(curl -fsSL "$METADATA_URL")"
  target_version="$(jq -r --arg b "$chrome_build" '.builds[$b].version // empty' <<<"$json")"
  [[ -n "$target_version" ]] || fail "no ChromeDriver version found for Chrome build $chrome_build"

  url="$(jq -r --arg b "$chrome_build" --arg p "$platform_key" '.builds[$b].downloads.chromedriver[]? | select(.platform == $p) | .url' <<<"$json" | head -n1)"
  [[ -n "$url" ]] || fail "no ChromeDriver download URL found for platform $platform_key and build $chrome_build"

  mkdir -p "$TOOLS_DIR"
  zip_file="$TOOLS_DIR/chromedriver-${target_version}-${platform_key}.zip"
  unpack_dir="$TOOLS_DIR/chromedriver-${target_version}-${platform_key}"
  driver="$unpack_dir/chromedriver-${platform_key}/chromedriver"

  if [[ ! -x "$driver" ]]; then
    curl -fsSL "$url" -o "$zip_file"
    rm -rf "$unpack_dir"
    unzip -q -o "$zip_file" -d "$unpack_dir"
    chmod +x "$driver"
  fi

  echo "$driver"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      INSTALL=1
      shift
      ;;
    --port)
      [[ $# -ge 2 ]] || fail "missing value for --port"
      CHROMEDRIVER_PORT="$2"
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

CHROME_BIN="$(chrome_binary)"
CHROME_VERSION="$(version_of "$CHROME_BIN")"
CHROME_MAJOR="$(major_of "$CHROME_VERSION")"
PLATFORM_KEY="$(platform)"

CHROMEDRIVER_BIN="${CHROMEDRIVER:-}"

if [[ -z "$CHROMEDRIVER_BIN" || ! -x "$CHROMEDRIVER_BIN" ]]; then
  if [[ "$INSTALL" -eq 1 ]]; then
    CHROMEDRIVER_BIN="$(download_matching_driver "$CHROME_VERSION" "$PLATFORM_KEY")"
  else
    fail "chromedriver not found. Re-run with --install or set CHROMEDRIVER."
  fi
fi

CHROMEDRIVER_VERSION="$(version_of "$CHROMEDRIVER_BIN")"
CHROMEDRIVER_MAJOR="$(major_of "$CHROMEDRIVER_VERSION")"

if [[ "$CHROMEDRIVER_MAJOR" != "$CHROME_MAJOR" ]]; then
  if [[ "$INSTALL" -eq 1 ]]; then
    CHROMEDRIVER_BIN="$(download_matching_driver "$CHROME_VERSION" "$PLATFORM_KEY")"
    CHROMEDRIVER_VERSION="$(version_of "$CHROMEDRIVER_BIN")"
    CHROMEDRIVER_MAJOR="$(major_of "$CHROMEDRIVER_VERSION")"
  else
    fail "Chrome major $CHROME_MAJOR does not match ChromeDriver major $CHROMEDRIVER_MAJOR. Re-run with --install."
  fi
fi

if [[ "$CHROMEDRIVER_MAJOR" != "$CHROME_MAJOR" ]]; then
  fail "Chrome/ChromeDriver major mismatch remains after install attempt."
fi

LOG_FILE="$ROOT_DIR/tmp/chromedriver.log"
mkdir -p "$(dirname "$LOG_FILE")"

"$CHROMEDRIVER_BIN" --port="$CHROMEDRIVER_PORT" >"$LOG_FILE" 2>&1 &
DRIVER_PID=$!
cleanup() {
  kill "$DRIVER_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

ready=0
for _ in $(seq 1 100); do
  if curl -fsS "http://127.0.0.1:${CHROMEDRIVER_PORT}/status" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.05
done
[[ "$ready" -eq 1 ]] || fail "chromedriver did not become ready on port $CHROMEDRIVER_PORT"

payload="$(jq -n --arg binary "$CHROME_BIN" '{
  capabilities: {
    alwaysMatch: {
      browserName: "chrome",
      webSocketUrl: true,
      "goog:chromeOptions": {
        binary: $binary,
        args: ["--headless=new", "--disable-gpu", "--no-sandbox"]
      }
    }
  }
}')"

response="$(
  curl -sS \
    -X POST \
    "http://127.0.0.1:${CHROMEDRIVER_PORT}/session" \
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

curl -sS -X DELETE "http://127.0.0.1:${CHROMEDRIVER_PORT}/session/${session_id}" >/dev/null || true

echo "BiDi readiness OK"
echo "chrome_binary=$CHROME_BIN"
echo "chrome_version=$CHROME_VERSION"
echo "chromedriver_binary=$CHROMEDRIVER_BIN"
echo "chromedriver_version=$CHROMEDRIVER_VERSION"
echo "webSocketUrl=$web_socket_url"
