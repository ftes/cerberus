#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$ROOT_DIR/tmp"
CLI_FIREFOX_VERSION=""
CLI_GECKODRIVER_VERSION=""
PLATFORM_KEY=""

usage() {
  cat <<'USAGE'
Usage: bin/firefox.sh [--firefox-version VERSION] [--geckodriver-version VERSION]

Ensures Firefox runtime binaries for Cerberus:
- ensures Firefox + GeckoDriver are installed under tmp,
- reuses existing binaries when already installed,
- prints resolved binary paths.

Options:
  --firefox-version VERSION      Override Firefox version for this run.
  --geckodriver-version VERSION  Override GeckoDriver version for this run.
  -h, --help                     Show this help.

Environment:
  CERBERUS_FIREFOX_VERSION      Default Firefox version when --firefox-version is not provided.
  CERBERUS_GECKODRIVER_VERSION  Default GeckoDriver version when --geckodriver-version is not provided.
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

resolve_default_firefox_version() {
  local version

  version="$(curl -fsSL "https://product-details.mozilla.org/1.0/firefox_versions.json" | jq -r '.LATEST_FIREFOX_VERSION // empty')"
  [[ -n "$version" ]] || fail "unable to resolve latest Firefox version"
  echo "$version"
}

resolve_firefox_version() {
  if [[ -n "$CLI_FIREFOX_VERSION" ]]; then
    echo "$CLI_FIREFOX_VERSION"
    return
  fi

  if [[ -n "${CERBERUS_FIREFOX_VERSION:-}" ]]; then
    echo "$CERBERUS_FIREFOX_VERSION"
    return
  fi

  resolve_default_firefox_version
}

resolve_geckodriver_version() {
  if [[ -n "$CLI_GECKODRIVER_VERSION" ]]; then
    echo "$CLI_GECKODRIVER_VERSION"
    return
  fi

  if [[ -n "${CERBERUS_GECKODRIVER_VERSION:-}" ]]; then
    echo "$CERBERUS_GECKODRIVER_VERSION"
    return
  fi

  echo "0.36.0"
}

firefox_download_url() {
  local version="$1"
  local platform_key="$2"

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
    *)
      fail "unsupported Firefox platform key: $platform_key"
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

version_of() {
  local binary="$1"
  "$binary" --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+(\.[0-9]+)?)?' | head -n1 || true
}

install_firefox() {
  local version="$1"
  local platform_key="$2"
  local install_dir="$TMP_DIR/firefox-${version}"
  local payload_dir="$install_dir/payload"
  local firefox_bin
  local stable_firefox_bin="$install_dir/firefox"
  local archive_file
  local download_url

  case "$platform_key" in
    mac-arm64|mac-x64)
      firefox_bin="$payload_dir/Firefox.app/Contents/MacOS/firefox"
      if [[ ! -x "$firefox_bin" ]]; then
        archive_file="$TMP_DIR/firefox-${version}-${platform_key}.dmg"
        download_url="$(firefox_download_url "$version" "$platform_key")"

        mkdir -p "$TMP_DIR"
        curl -fsSL "$download_url" -o "$archive_file"
        rm -rf "$install_dir"
        mkdir -p "$payload_dir"

        local mount_dir
        mount_dir="$TMP_DIR/firefox-mount-${version}-${platform_key}"
        mkdir -p "$mount_dir"
        hdiutil attach "$archive_file" -nobrowse -readonly -mountpoint "$mount_dir" >/dev/null
        cp -R "$mount_dir/Firefox.app" "$payload_dir/Firefox.app"
        hdiutil detach "$mount_dir" >/dev/null || true
        rmdir "$mount_dir" >/dev/null 2>&1 || true
      fi
      ;;
    linux64|linux-arm64)
      firefox_bin="$payload_dir/firefox/firefox"
      if [[ ! -x "$firefox_bin" ]]; then
        archive_file="$TMP_DIR/firefox-${version}-${platform_key}.tar.xz"
        download_url="$(firefox_download_url "$version" "$platform_key")"

        mkdir -p "$TMP_DIR"
        curl -fsSL "$download_url" -o "$archive_file"
        rm -rf "$install_dir"
        mkdir -p "$payload_dir"
        tar -xf "$archive_file" -C "$payload_dir"
      fi
      ;;
    *)
      fail "unsupported Firefox platform key: $platform_key"
      ;;
  esac

  [[ -x "$firefox_bin" ]] || fail "installed Firefox binary is not executable: $firefox_bin"
  ln -sf "$firefox_bin" "$stable_firefox_bin"
  [[ -x "$stable_firefox_bin" ]] || fail "stable firefox binary path is not executable: $stable_firefox_bin"
  FIREFOX_BIN="$stable_firefox_bin"
}

install_geckodriver() {
  local version="$1"
  local platform_key="$2"
  local gecko_platform
  local install_dir="$TMP_DIR/geckodriver-${version}"
  local geckodriver_bin="$install_dir/geckodriver"
  local archive_file
  local download_url

  gecko_platform="$(geckodriver_platform_key "$platform_key")"

  if [[ ! -x "$geckodriver_bin" ]]; then
    archive_file="$TMP_DIR/geckodriver-${version}-${gecko_platform}.tar.gz"
    download_url="$(geckodriver_download_url "$version" "$gecko_platform")"

    mkdir -p "$TMP_DIR"
    curl -fsSL "$download_url" -o "$archive_file"
    rm -rf "$install_dir"
    mkdir -p "$install_dir"
    tar -xzf "$archive_file" -C "$install_dir"
    chmod +x "$geckodriver_bin"
  fi

  [[ -x "$geckodriver_bin" ]] || fail "installed GeckoDriver is not executable: $geckodriver_bin"
  GECKODRIVER_BIN="$geckodriver_bin"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --firefox-version)
      [[ $# -ge 2 ]] || fail "missing value for --firefox-version"
      CLI_FIREFOX_VERSION="$2"
      shift 2
      ;;
    --geckodriver-version)
      [[ $# -ge 2 ]] || fail "missing value for --geckodriver-version"
      CLI_GECKODRIVER_VERSION="$2"
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
FIREFOX_VERSION_REQUESTED="$(resolve_firefox_version)"
GECKODRIVER_VERSION_REQUESTED="$(resolve_geckodriver_version)"

install_firefox "$FIREFOX_VERSION_REQUESTED" "$PLATFORM_KEY"
install_geckodriver "$GECKODRIVER_VERSION_REQUESTED" "$PLATFORM_KEY"

FIREFOX_VERSION="$(version_of "$FIREFOX_BIN")"
GECKODRIVER_VERSION="$(version_of "$GECKODRIVER_BIN")"

[[ -n "$FIREFOX_VERSION" ]] || fail "unable to determine Firefox version from $FIREFOX_BIN"
[[ -n "$GECKODRIVER_VERSION" ]] || fail "unable to determine GeckoDriver version from $GECKODRIVER_BIN"

echo "Firefox runtime ready"
echo "firefox_binary=$FIREFOX_BIN"
echo "firefox_version=$FIREFOX_VERSION"
echo "geckodriver_binary=$GECKODRIVER_BIN"
echo "geckodriver_version=$GECKODRIVER_VERSION"
