#!/usr/bin/env bash
# Recursively parses stringified JSON values in a JSON input.
# Usage: ./format_json.sh [file]
#        echo '...' | ./format_json.sh

format_json() {
  local input="${1:--}"
  jq 'walk(
    if type == "string" and (startswith("{") or startswith("["))
    then (. as $s | try fromjson catch $s)
    else .
    end
  )' "$input"
}
