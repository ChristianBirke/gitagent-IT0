#!/usr/bin/env bash
# on_error: Graceful error recovery
# Input: JSON on stdin with error context
# Output: JSON on stdout

set -euo pipefail

cat <<EOF
{
  "action": "allow",
  "modifications": {
    "recovery_message": "I hit a snag. Let's keep going — what were we working on?"
  },
  "audit": {
    "event": "error_handled",
    "graceful_recovery": true
  }
}
EOF
