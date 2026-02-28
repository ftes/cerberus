#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BROWSER="${CERBERUS_BIDI_BROWSER:-chrome}"

usage() {
  cat <<'USAGE'
Usage: bin/check_browser_bidi_ready.sh [chrome|firefox] [--install] [--port PORT]
       bin/check_browser_bidi_ready.sh --browser chrome|firefox [--install] [--port PORT]

Runs the browser-specific BiDi readiness check script.

Examples:
  bin/check_browser_bidi_ready.sh chrome --install
  bin/check_browser_bidi_ready.sh firefox --install
  bin/check_browser_bidi_ready.sh --browser firefox --port 4546
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --browser)
      [[ $# -ge 2 ]] || {
        echo "ERROR: missing value for --browser" >&2
        exit 1
      }
      BROWSER="$2"
      shift 2
      ;;
    chrome|firefox|gecko)
      BROWSER="$1"
      shift
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

case "$BROWSER" in
  chrome)
    exec "$ROOT_DIR/bin/check_chrome_bidi_ready.sh" "$@"
    ;;
  firefox|gecko)
    exec "$ROOT_DIR/bin/check_firefox_bidi_ready.sh" "$@"
    ;;
  *)
    echo "ERROR: unknown browser '$BROWSER' (expected chrome or firefox)" >&2
    usage >&2
    exit 1
    ;;
esac
