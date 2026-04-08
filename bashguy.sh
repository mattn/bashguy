# bashguy.sh - source this file in your .bashrc
# Usage: source /path/to/bashguy.sh
# Then press Ctrl+G to enter prompt mode

_bashguy_widget() {
  local prefix="${READLINE_LINE:0:$READLINE_POINT}"
  local suffix="${READLINE_LINE:$READLINE_POINT}"
  local cmd
  cmd=$(
    saved_tty=$(stty -g </dev/tty)
    stty sane </dev/tty
    trap 'stty "$saved_tty" </dev/tty; exit 1' INT
    echo -n "[bashguy] " >/dev/tty
    IFS= read -r prompt </dev/tty || { stty "$saved_tty" </dev/tty; exit 1; }
    if [ -n "$prompt" ]; then
      echo -ne "\e[A\r\e[K[bashguy] ${prompt} generating..." >/dev/tty
      if [ -n "$prefix" ] || [ -n "$suffix" ]; then
        system="You are a bash command generator. The user has a partially written command line. The text before the cursor is: $(printf '%s' "$prefix" | sed 's/"/\\"/g')
The text after the cursor is: $(printf '%s' "$suffix" | sed 's/"/\\"/g')
Output ONLY the text to insert at the cursor position (no explanation, no markdown, no code fences, no trailing newline). The inserted text combined with the existing text should form a valid bash command. Current directory: $(pwd)"
      else
        system="You are a bash command generator. The user describes what they want to do in natural language. Output ONLY a single bash command (no explanation, no markdown, no code fences, no trailing newline). The command should work on Linux. Current directory: $(pwd)"
      fi
      result=$(claude --no-session-persistence -p --model "${BASHGUY_MODEL:-claude-sonnet-4-20250514}" --system-prompt "$system" "$prompt" 2>/dev/null)
      echo -ne "\r\e[K" >/dev/tty
      printf '%s' "$result"
    fi
    stty "$saved_tty" </dev/tty
  )
  if [ -n "$cmd" ]; then
    READLINE_LINE="${prefix}${cmd}${suffix}"
    READLINE_POINT=$(( ${#prefix} + ${#cmd} ))
  fi
}
