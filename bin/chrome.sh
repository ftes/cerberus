#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$ROOT_DIR/tmp"
METADATA_URL="https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json"
LATEST_METADATA_URL="https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
PLATFORM_KEY=""
CLI_CHROME_VERSION=""

usage() {
  cat <<'USAGE'
Usage: bin/chrome.sh [--version VERSION]

Ensures Chrome runtime binaries for Cerberus:
- ensures Chrome for Testing + matching ChromeDriver are installed under tmp,
- reuses existing binaries when already installed,
- prints resolved binary paths.

Options:
  --version VERSION  Override Chrome/CfT version for this run.
  -h, --help         Show this help.

Environment:
  CERBERUS_CHROME_VERSION  Default version when --version is not provided.
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

version_of() {
  local binary="$1"
  "$binary" --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true
}

resolve_default_chrome_version() {
  local version

  version="$(curl -fsSL "$LATEST_METADATA_URL" | jq -r '.channels.Stable.version // empty')"
  [[ -n "$version" ]] || fail "unable to resolve latest Stable Chrome version"
  echo "$version"
}

resolve_chrome_version() {
  if [[ -n "$CLI_CHROME_VERSION" ]]; then
    echo "$CLI_CHROME_VERSION"
    return
  fi

  if [[ -n "${CERBERUS_CHROME_VERSION:-}" ]]; then
    echo "$CERBERUS_CHROME_VERSION"
    return
  fi

  resolve_default_chrome_version
}

lookup_download_url() {
  local version="$1"
  local artifact="$2"
  local platform_key="$3"
  local json
  local url

  json="$(curl -fsSL "$METADATA_URL")"

  url="$({
    jq -r \
      --arg v "$version" \
      --arg a "$artifact" \
      --arg p "$platform_key" \
      '.versions[] | select(.version == $v) | .downloads[$a][]? | select(.platform == $p) | .url' \
      <<<"$json" | head -n1
  })"

  [[ -n "$url" ]] || fail "no $artifact download URL found for version $version and platform $platform_key"
  echo "$url"
}

install_artifact() {
  local artifact="$1"
  local version="$2"
  local platform_key="$3"
  local install_dir="$4"
  local url
  local zip_file

  mkdir -p "$TMP_DIR"
  url="$(lookup_download_url "$version" "$artifact" "$platform_key")"
  zip_file="$TMP_DIR/${artifact}-${version}-${platform_key}.zip"

  curl -fsSL "$url" -o "$zip_file"
  rm -rf "$install_dir"
  mkdir -p "$install_dir"
  unzip -q -o "$zip_file" -d "$install_dir"
}

ensure_runtime() {
  local version="$1"
  local platform_key="$2"
  local chrome_dir="$TMP_DIR/chrome-${version}"
  local chromedriver_dir="$TMP_DIR/chromedriver-${version}"
  local chrome_bin="$chrome_dir/$(chrome_binary_relpath "$platform_key")"
  local chromedriver_bin="$chromedriver_dir/$(chromedriver_binary_relpath "$platform_key")"
  local stable_chrome_bin="$chrome_dir/chrome"
  local stable_chromedriver_bin="$chromedriver_dir/chromedriver"

  if [[ ! -x "$chrome_bin" ]]; then
    install_artifact "chrome" "$version" "$platform_key" "$chrome_dir"
  fi

  if [[ ! -x "$chromedriver_bin" ]]; then
    install_artifact "chromedriver" "$version" "$platform_key" "$chromedriver_dir"
  fi

  [[ -x "$chrome_bin" ]] || fail "installed chrome binary is not executable: $chrome_bin"
  [[ -x "$chromedriver_bin" ]] || fail "installed chromedriver binary is not executable: $chromedriver_bin"

  cat > "$stable_chrome_bin" <<EOF
#!/usr/bin/env bash
exec "${chrome_bin}" "\$@"
EOF
  chmod +x "$stable_chrome_bin"
  ln -sf "$chromedriver_bin" "$stable_chromedriver_bin"

  [[ -x "$stable_chrome_bin" ]] || fail "stable chrome binary path is not executable: $stable_chrome_bin"
  [[ -x "$stable_chromedriver_bin" ]] || fail "stable chromedriver binary path is not executable: $stable_chromedriver_bin"

  CHROME_BIN="$chrome_bin"
  CHROMEDRIVER_BIN="$stable_chromedriver_bin"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      [[ $# -ge 2 ]] || fail "missing value for --version"
      CLI_CHROME_VERSION="$2"
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
CHROME_VERSION_REQUESTED="$(resolve_chrome_version)"
ensure_runtime "$CHROME_VERSION_REQUESTED" "$PLATFORM_KEY"

CHROME_VERSION="$CHROME_VERSION_REQUESTED"

CHROMEDRIVER_VERSION="$(version_of "$CHROMEDRIVER_BIN")"
[[ -n "$CHROMEDRIVER_VERSION" ]] || fail "unable to determine ChromeDriver version from $CHROMEDRIVER_BIN"

echo "Chrome runtime ready"
echo "chrome_binary=$CHROME_BIN"
echo "chrome_version=$CHROME_VERSION"
echo "chromedriver_binary=$CHROMEDRIVER_BIN"
echo "chromedriver_version=$CHROMEDRIVER_VERSION"
