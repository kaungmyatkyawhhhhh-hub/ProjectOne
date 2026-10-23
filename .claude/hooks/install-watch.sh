#!/bin/sh
# Installs the watch plugin (bradautomates/claude-video, pinned to v0.3.2) in cloud sessions and points it at Gemini.
# The network proxy adds the real Gemini key, so the key written below is only a placeholder.
[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0
if command -v claude >/dev/null 2>&1 && ! grep -q '"watch@claude-video"' "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null; then
  claude plugin marketplace add "bradautomates/claude-video#v0.3.2" >/dev/null 2>&1
  claude plugin install watch@claude-video >/dev/null 2>&1
fi
command -v yt-dlp >/dev/null 2>&1 || python3 -m pip install -q yt-dlp >/dev/null 2>&1
CONF="$HOME/.config/watch/.env"
if [ ! -f "$CONF" ]; then
  mkdir -p "$HOME/.config/watch"
  (umask 077; printf 'GEMINI_API_KEY=proxy-injected\nWATCH_ENGINE="gemini"\nWATCH_GEMINI_MODEL="gemini-3.8-flash"\nSETUP_COMPLETE="true"\n' > "$CONF")
fi
exit 0
