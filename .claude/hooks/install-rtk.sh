#!/bin/sh
# Installs RTK (Rust Token Killer) in cloud sessions so the PreToolUse hook can compress shell output.
[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0
command -v rtk >/dev/null 2>&1 && exit 0
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/tags/v0.51.0/install.sh \
  | RTK_VERSION=v0.51.0 sh >/dev/null 2>&1 || true
exit 0
