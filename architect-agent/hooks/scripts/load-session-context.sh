#!/usr/bin/env bash
# on_session_start: Load recent memory and check for pending decisions
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
  decisions=$(grep -A 20 "## Pending Evaluations" "$MEMORY_FILE" 2>/dev/null | head -20 || true)
  if [ -n "$decisions" ] && ! echo "$decisions" | grep -q "No pending evaluations"; then
    context="Pending decisions found. Review with user."
  fi
fi

# Output action: allow session to proceed, inject context
cat <<JSONEOF
{
  "action": "allow",
  "audit": {
    "event": "session_start",
    "memory_loaded": true,
    "has_pending_decisions": $([ -n "$context" ] && echo "true" || echo "false")
  }
}
JSONEOF
