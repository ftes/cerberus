#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${CERBERUS_BROWSER_TOOLS_DIR:-$ROOT_DIR/tmp/browser-tools}"
CHROMEDRIVER_PORT="${CERBERUS_CHROMEDRIVER_PORT:-9515}"
PINNED_CHROME_VERSION="${CERBERUS_CHROME_VERSION:-145.0.7632.117}"
METADATA_URL="https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json"

INSTALL=0
PLATFORM_KEY=""
INSTALL_CHROME_BIN=""
INSTALL_CHROMEDRIVER_BIN=""

usage() {
  cat <<'USAGE'
Usage: bin/check_bidi_ready.sh [--install] [--port PORT]

Checks WebDriver BiDi readiness for Cerberus:
- verifies Chrome and ChromeDriver versions/builds,
- optionally installs a pinned Chrome for Testing + matching ChromeDriver under tmp/browser-tools,
- performs a WebDriver session handshake with `webSocketUrl: true`.

Environment:
  CHROME         Required path to Chrome binary (unless --install is used).
  CHROMEDRIVER   Required path to ChromeDriver binary (unless --install is used).
  CERBERUS_CHROME_VERSION  Pinned Chrome/CfT version (default: 145.0.7632.117).

Options:
  --install     Download pinned Chrome + matching ChromeDriver and use local binaries.
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

chrome_binary_relpath() {
  local platform_key="$1"
  case "$platform_key" in
    mac-arm64) echo "chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" ;;
    mac-x64) echo "chrome-mac-x64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" ;;
    linux64) echo "chrome-linux64/chrome" ;;
    *) fail "unsupported Chrome platform key: $platform_key" ;;
  esac
}

chromedriver_binary_relpath() {
  local platform_key="$1"
  echo "chromedriver-${platform_key}/chromedriver"
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

chromedriver_binary() {
  local configured="${CHROMEDRIVER:-}"

  if [[ -n "$configured" ]]; then
    [[ -x "$configured" ]] || fail "CHROMEDRIVER is not executable: $configured"
    echo "$configured"
    return
  fi

  fail "chromedriver not found. Set CHROMEDRIVER or use --install."
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

lookup_download_url() {
  local version="$1"
  local artifact="$2"
  local platform_key="$3"
  local json
  local url

  json="$(curl -fsSL "$METADATA_URL")"

  url="$(
    jq -r \
      --arg v "$version" \
      --arg a "$artifact" \
      --arg p "$platform_key" \
      '.versions[] | select(.version == $v) | .downloads[$a][]? | select(.platform == $p) | .url' \
      <<<"$json" | head -n1
  )"

  [[ -n "$url" ]] || fail "no $artifact download URL found for version $version and platform $platform_key"
  echo "$url"
}

download_artifact() {
  local artifact="$1"
  local version="$2"
  local platform_key="$3"
  local url
  local zip_file
  local unpack_dir

  mkdir -p "$TOOLS_DIR"
  url="$(lookup_download_url "$version" "$artifact" "$platform_key")"
  zip_file="$TOOLS_DIR/${artifact}-${version}-${platform_key}.zip"
  unpack_dir="$TOOLS_DIR/${artifact}-${version}-${platform_key}"

  if [[ ! -d "$unpack_dir" ]]; then
    curl -fsSL "$url" -o "$zip_file"
    rm -rf "$unpack_dir"
    unzip -q -o "$zip_file" -d "$unpack_dir"
  fi

  echo "$unpack_dir"
}

write_env_file() {
  local chrome_bin="$1"
  local chromedriver_bin="$2"
  local env_file="$TOOLS_DIR/env.sh"

  {
    printf "export CERBERUS_BROWSER_TOOLS_DIR=%q\n" "$TOOLS_DIR"
    printf "export CERBERUS_CHROME_VERSION=%q\n" "$PINNED_CHROME_VERSION"
    printf "export CERBERUS_CFT_PLATFORM=%q\n" "$PLATFORM_KEY"
    printf "export CHROME=%q\n" "$chrome_bin"
    printf "export CHROMEDRIVER=%q\n" "$chromedriver_bin"
  } >"$env_file"
}

install_pinned_runtime() {
  local chrome_unpack
  local chromedriver_unpack
  local chrome_bin
  local chromedriver_bin

  chrome_unpack="$(download_artifact "chrome" "$PINNED_CHROME_VERSION" "$PLATFORM_KEY")"
  chromedriver_unpack="$(download_artifact "chromedriver" "$PINNED_CHROME_VERSION" "$PLATFORM_KEY")"

  chrome_bin="$chrome_unpack/$(chrome_binary_relpath "$PLATFORM_KEY")"
  chromedriver_bin="$chromedriver_unpack/$(chromedriver_binary_relpath "$PLATFORM_KEY")"

  [[ -x "$chrome_bin" ]] || fail "installed chrome binary is not executable: $chrome_bin"
  [[ -x "$chromedriver_bin" ]] || fail "installed chromedriver binary is not executable: $chromedriver_bin"

  write_env_file "$chrome_bin" "$chromedriver_bin"
  INSTALL_CHROME_BIN="$chrome_bin"
  INSTALL_CHROMEDRIVER_BIN="$chromedriver_bin"
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

PLATFORM_KEY="$(platform)"

if [[ "$INSTALL" -eq 1 ]]; then
  install_pinned_runtime
  CHROME_BIN="$INSTALL_CHROME_BIN"
  CHROMEDRIVER_BIN="$INSTALL_CHROMEDRIVER_BIN"
else
  CHROME_BIN="$(chrome_binary)"
  CHROMEDRIVER_BIN="$(chromedriver_binary)"
fi

CHROME_VERSION="$(version_of "$CHROME_BIN")"
CHROME_MAJOR="$(major_of "$CHROME_VERSION")"
CHROME_BUILD="$(build_of "$CHROME_VERSION")"
[[ -n "$CHROME_VERSION" ]] || fail "unable to determine Chrome version from $CHROME_BIN"

CHROMEDRIVER_VERSION="$(version_of "$CHROMEDRIVER_BIN")"
CHROMEDRIVER_MAJOR="$(major_of "$CHROMEDRIVER_VERSION")"
CHROMEDRIVER_BUILD="$(build_of "$CHROMEDRIVER_VERSION")"
[[ -n "$CHROMEDRIVER_VERSION" ]] || fail "unable to determine ChromeDriver version from $CHROMEDRIVER_BIN"

if [[ "$CHROMEDRIVER_MAJOR" != "$CHROME_MAJOR" ]]; then
  fail "Chrome major $CHROME_MAJOR does not match ChromeDriver major $CHROMEDRIVER_MAJOR."
fi

if [[ "$CHROME_BUILD" != "$CHROMEDRIVER_BUILD" ]]; then
  fail "Chrome build $CHROME_BUILD does not match ChromeDriver build $CHROMEDRIVER_BUILD."
fi

if [[ "$INSTALL" -eq 1 ]]; then
  if [[ "$CHROME_VERSION" != "$PINNED_CHROME_VERSION" ]]; then
    fail "installed Chrome version $CHROME_VERSION does not match pinned $PINNED_CHROME_VERSION."
  fi

  if [[ "$CHROMEDRIVER_VERSION" != "$PINNED_CHROME_VERSION" ]]; then
    fail "installed ChromeDriver version $CHROMEDRIVER_VERSION does not match pinned $PINNED_CHROME_VERSION."
  fi
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
if [[ "$INSTALL" -eq 1 ]]; then
  echo "env_file=$TOOLS_DIR/env.sh"
fi
