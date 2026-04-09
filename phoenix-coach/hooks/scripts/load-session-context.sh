#!/usr/bin/env bash
# on_session_start: Load recent memory and check outstanding commitments
# Input: JSON on stdin with session context
# Output: JSON on stdout with modifications

set -euo pipefail

MEMORY_DIR="$(dirname "$0")/../../memory"
MEMORY_FILE="${MEMORY_DIR}/MEMORY.md"
CONTEXT_FILE="${MEMORY_DIR}/runtime/context.md"
DAILYLOG_FILE="${MEMORY_DIR}/runtime/dailylog.md"

# Read available context
context=""

if [ -f "$MEMORY_FILE" ]; then
  commitments=$(grep -A 20 "## Open Commitments" "$MEMORY_FILE" 2>/dev/null | head -20 || true)
  if [ -n "$commitments" ] && ! echo "$commitments" | grep -q "No open commitments"; then
    context="Outstanding commitments found. Review with user."
  fi
fi

# Output action: allow session to proceed, inject context
cat <<EOF
{
  "action": "allow",
  "audit": {
    "event": "session_start",
    "memory_loaded": true,
    "has_commitments": $([ -n "$context" ] && echo "true" || echo "false")
  }
}
EOF
