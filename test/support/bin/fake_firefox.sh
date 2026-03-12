#!/bin/sh

PORT_NUMBER=""

while [ "$#" -gt 0 ]; do
  if [ "$1" = "--remote-debugging-port" ]; then
    shift
    PORT_NUMBER="$1"
  fi

  shift
done

if [ -z "$PORT_NUMBER" ]; then
  PORT_NUMBER="0"
fi

echo "WebDriver BiDi listening on ws://127.0.0.1:${PORT_NUMBER}"

while true; do
  sleep 60
done
