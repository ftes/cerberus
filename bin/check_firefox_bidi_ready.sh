#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${CERBERUS_BROWSER_TOOLS_DIR:-$ROOT_DIR/tmp/browser-tools}"
GECKODRIVER_PORT="${CERBERUS_GECKODRIVER_PORT:-4545}"
PINNED_FIREFOX_VERSION="${CERBERUS_FIREFOX_VERSION:-latest}"
PINNED_GECKODRIVER_VERSION="${CERBERUS_GECKODRIVER_VERSION:-0.36.0}"

INSTALL=0
PLATFORM_KEY=""
INSTALL_FIREFOX_BIN=""
INSTALL_GECKODRIVER_BIN=""

usage() {
  cat <<'USAGE'
Usage: bin/check_firefox_bidi_ready.sh [--install] [--port PORT]

Checks Firefox WebDriver BiDi readiness for Cerberus:
- verifies Firefox and GeckoDriver are available,
- optionally installs Firefox + matching GeckoDriver under tmp/browser-tools,
- starts local GeckoDriver,
- performs a WebDriver session handshake with `webSocketUrl: true`.

Environment:
  FIREFOX                    Required path to Firefox binary (unless --install is used).
  GECKODRIVER                Required path to GeckoDriver binary (unless --install is used).
  CERBERUS_FIREFOX_VERSION   Firefox version to install (default: latest).
  CERBERUS_GECKODRIVER_VERSION  GeckoDriver version to install (default: 0.36.0).

Options:
  --install     Download Firefox + GeckoDriver and use local binaries.
  --port PORT   Local GeckoDriver HTTP port (default: 4545).
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
    Linux:aarch64) echo "linux-arm64" ;;
    *) fail "unsupported platform $(uname -s):$(uname -m)" ;;
  esac
}

firefox_download_url() {
  local version="$1"
  local platform_key="$2"
  local os_key

  case "$platform_key" in
    mac-arm64|mac-x64) os_key="osx" ;;
    linux64) os_key="linux64" ;;
    linux-arm64) os_key="linux-aarch64" ;;
    *) fail "unsupported Firefox platform key: $platform_key" ;;
  esac

  if [[ "$version" == "latest" ]]; then
    echo "https://download.mozilla.org/?product=firefox-latest&os=${os_key}&lang=en-US"
    return
  fi

  case "$platform_key" in
    mac-arm64|mac-x64)
      echo "https://archive.mozilla.org/pub/firefox/releases/${version}/mac/en-US/Firefox%20${version}.dmg"
      ;;
    linux64)
      echo "https://archive.mozilla.org/pub/firefox/releases/${version}/linux-x86_64/en-US/firefox-${version}.tar.xz"
      ;;
    linux-arm64)
      echo "https://archive.mozilla.org/pub/firefox/releases/${version}/linux-aarch64/en-US/firefox-${version}.tar.xz"
      ;;
  esac
}

geckodriver_platform_key() {
  local platform_key="$1"

  case "$platform_key" in
    mac-arm64) echo "macos-aarch64" ;;
    mac-x64) echo "macos" ;;
    linux64) echo "linux64" ;;
    linux-arm64) echo "linux-aarch64" ;;
    *) fail "unsupported GeckoDriver platform key: $platform_key" ;;
  esac
}

geckodriver_download_url() {
  local version="$1"
  local platform_key="$2"

  echo "https://github.com/mozilla/geckodriver/releases/download/v${version}/geckodriver-v${version}-${platform_key}.tar.gz"
}

firefox_binary() {
  local configured="${FIREFOX:-}"

  if [[ -n "$configured" ]]; then
    [[ -x "$configured" ]] || fail "FIREFOX is not executable: $configured"
    echo "$configured"
    return
  fi

  fail "FIREFOX is not set. Set FIREFOX or use --install."
}

geckodriver_binary() {
  local configured="${GECKODRIVER:-}"

  if [[ -n "$configured" ]]; then
    [[ -x "$configured" ]] || fail "GECKODRIVER is not executable: $configured"
    echo "$configured"
    return
  fi

  fail "GECKODRIVER is not set. Set GECKODRIVER or use --install."
}

version_of() {
  local binary="$1"
  "$binary" --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+(\.[0-9]+)?)?' | head -n1 || true
}

write_env_file() {
  local firefox_bin="$1"
  local geckodriver_bin="$2"
  local env_file="$TOOLS_DIR/env.sh"

  {
    printf "export CERBERUS_BROWSER_TOOLS_DIR=%q\n" "$TOOLS_DIR"
    printf "export CERBERUS_FIREFOX_VERSION=%q\n" "$PINNED_FIREFOX_VERSION"
    printf "export CERBERUS_GECKODRIVER_VERSION=%q\n" "$PINNED_GECKODRIVER_VERSION"
    printf "export CERBERUS_FIREFOX_PLATFORM=%q\n" "$PLATFORM_KEY"
    printf "export FIREFOX=%q\n" "$firefox_bin"
    printf "export GECKODRIVER=%q\n" "$geckodriver_bin"
  } >"$env_file"
}

install_firefox() {
  local unpack_dir="$TOOLS_DIR/firefox-${PINNED_FIREFOX_VERSION}-${PLATFORM_KEY}"
  local firefox_bin
  local download_url

  mkdir -p "$TOOLS_DIR"
  download_url="$(firefox_download_url "$PINNED_FIREFOX_VERSION" "$PLATFORM_KEY")"

  case "$PLATFORM_KEY" in
    mac-arm64|mac-x64)
      firefox_bin="$unpack_dir/Firefox.app/Contents/MacOS/firefox"
      if [[ ! -x "$firefox_bin" ]]; then
        local archive_file="$TOOLS_DIR/firefox-${PINNED_FIREFOX_VERSION}-${PLATFORM_KEY}.dmg"
        local mount_dir="$TOOLS_DIR/firefox-mount-${PINNED_FIREFOX_VERSION}-${PLATFORM_KEY}"

        curl -fsSL "$download_url" -o "$archive_file"
        rm -rf "$unpack_dir"
        mkdir -p "$unpack_dir"
        mkdir -p "$mount_dir"

        hdiutil attach "$archive_file" -nobrowse -readonly -mountpoint "$mount_dir" >/dev/null
        cp -R "$mount_dir/Firefox.app" "$unpack_dir/Firefox.app"
        hdiutil detach "$mount_dir" >/dev/null
        rmdir "$mount_dir" >/dev/null 2>&1 || true
      fi
      ;;
    linux64|linux-arm64)
      firefox_bin="$unpack_dir/firefox/firefox"
      if [[ ! -x "$firefox_bin" ]]; then
        local archive_file="$TOOLS_DIR/firefox-${PINNED_FIREFOX_VERSION}-${PLATFORM_KEY}.tar.xz"

        curl -fsSL "$download_url" -o "$archive_file"
        rm -rf "$unpack_dir"
        mkdir -p "$unpack_dir"
        tar -xf "$archive_file" -C "$unpack_dir"
      fi
      ;;
    *)
      fail "unsupported Firefox platform key: $PLATFORM_KEY"
      ;;
  esac

  [[ -x "$firefox_bin" ]] || fail "installed Firefox binary is not executable: $firefox_bin"
  INSTALL_FIREFOX_BIN="$firefox_bin"
}

install_geckodriver() {
  local platform_key
  local unpack_dir="$TOOLS_DIR/geckodriver-${PINNED_GECKODRIVER_VERSION}-${PLATFORM_KEY}"
  local geckodriver_bin="$unpack_dir/geckodriver"
  local archive_file
  local download_url

  platform_key="$(geckodriver_platform_key "$PLATFORM_KEY")"
  archive_file="$TOOLS_DIR/geckodriver-${PINNED_GECKODRIVER_VERSION}-${platform_key}.tar.gz"
  download_url="$(geckodriver_download_url "$PINNED_GECKODRIVER_VERSION" "$platform_key")"

  mkdir -p "$TOOLS_DIR"

  if [[ ! -x "$geckodriver_bin" ]]; then
    curl -fsSL "$download_url" -o "$archive_file"
    rm -rf "$unpack_dir"
    mkdir -p "$unpack_dir"
    tar -xzf "$archive_file" -C "$unpack_dir"
    chmod +x "$geckodriver_bin"
  fi

  [[ -x "$geckodriver_bin" ]] || fail "installed GeckoDriver is not executable: $geckodriver_bin"
  INSTALL_GECKODRIVER_BIN="$geckodriver_bin"
}

install_runtime() {
  install_firefox
  install_geckodriver
  write_env_file "$INSTALL_FIREFOX_BIN" "$INSTALL_GECKODRIVER_BIN"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      INSTALL=1
      shift
      ;;
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

PLATFORM_KEY="$(platform)"

if [[ "$INSTALL" -eq 1 ]]; then
  install_runtime
  FIREFOX_BIN="$INSTALL_FIREFOX_BIN"
  GECKODRIVER_BIN="$INSTALL_GECKODRIVER_BIN"
else
  FIREFOX_BIN="$(firefox_binary)"
  GECKODRIVER_BIN="$(geckodriver_binary)"
fi

FIREFOX_VERSION="$(version_of "$FIREFOX_BIN")"
GECKODRIVER_VERSION="$(version_of "$GECKODRIVER_BIN")"

[[ -n "$FIREFOX_VERSION" ]] || fail "unable to determine Firefox version from $FIREFOX_BIN"
[[ -n "$GECKODRIVER_VERSION" ]] || fail "unable to determine GeckoDriver version from $GECKODRIVER_BIN"

if [[ "$INSTALL" -eq 1 && "$PINNED_GECKODRIVER_VERSION" != "$GECKODRIVER_VERSION" ]]; then
  fail "installed GeckoDriver version $GECKODRIVER_VERSION does not match pinned $PINNED_GECKODRIVER_VERSION."
fi

LOG_FILE="$ROOT_DIR/tmp/geckodriver.log"
mkdir -p "$(dirname "$LOG_FILE")"

"$GECKODRIVER_BIN" --port "$GECKODRIVER_PORT" >"$LOG_FILE" 2>&1 &
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

payload="$(jq -n --arg binary "$FIREFOX_BIN" '{
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
echo "firefox_binary=$FIREFOX_BIN"
echo "firefox_version=$FIREFOX_VERSION"
echo "geckodriver_binary=$GECKODRIVER_BIN"
echo "geckodriver_version=$GECKODRIVER_VERSION"
echo "webSocketUrl=$web_socket_url"
if [[ "$INSTALL" -eq 1 ]]; then
  echo "env_file=$TOOLS_DIR/env.sh"
fi
