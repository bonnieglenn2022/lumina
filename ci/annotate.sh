#!/bin/bash
# Turns the important lines of an Xcode log into one GitHub annotation that can be read
# without downloading the log.  Usage: ci/annotate.sh <error|warning|notice> "<title>" <log file>
level="$1"; title="$2"; log="$3"

lines=$(grep -E "error:|[Ee]rror.*(profile|certificate|signing|team|agreement|device)|Communication with Apple|requires a provisioning profile|No profiles for|No Accounts|No signing certificate|license agreement|has not accepted|is not available|failed with" "$log" \
  | grep -vE "^\s*/Applications/Xcode" \
  | sed "s#$PWD/##g" | awk '!seen[$0]++' | head -40)
[ -n "$lines" ] || lines=$(tail -30 "$log")

encoded=$(printf '%s\n' "$lines" | awk 'BEGIN { ORS = "%0A" } { gsub(/%/, "%25"); gsub(/\r/, ""); print }')
echo "::${level} title=${title}::${encoded}"
