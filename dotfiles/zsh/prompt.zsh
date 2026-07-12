autoload -Uz add-zsh-hook

typeset -g __prompt_spacing_ran_command=0
typeset -g __prompt_first_line_cols=0
typeset -g __prompt_time_col=1
typeset -g __prompt_path_plain=""
typeset -g __prompt_path_prompt=""

prompt_arrow_style() {
  print "%F{245}"
}

prompt_user() {
  local user="${USER:-${LOGNAME:-}}"
  [[ -n "$user" ]] || user="$(command id -un 2>/dev/null)"
  user="${user//\%/%%}"
  print -r -- "$user"
}

prompt_path_segments() {
  local cwd cwd_display envrc root root_display parent base rel prefix suffix
  cwd="$PWD"
  cwd_display="${cwd/#$HOME/~}"

  __prompt_path_plain="$cwd_display"
  __prompt_path_prompt="${cwd_display//\%/%%}"

  if envrc="$(direnv status --json 2>/dev/null | jq -r '.state.loadedRC.path // empty' 2>/dev/null)"; then
    root="${envrc:h}"
  fi

  if [[ -n "$root" && ( "$cwd" == "$root" || "$cwd" == "$root/"* ) ]]; then
    root_display="${root/#$HOME/~}"
    parent="${root_display:h}"
    base="${root_display:t}"
    rel="${cwd#$root}"
    rel="${rel#/}"

    if [[ "$parent" == "/" ]]; then
      prefix="/"
    elif [[ "$parent" == "." ]]; then
      prefix=""
    else
      prefix="${parent}/"
    fi

    suffix="${rel:+/$rel}"
    __prompt_path_prompt="%F{245}${prefix//\%/%%}%U${base//\%/%%}%u${suffix//\%/%%}%F{245}"
  fi
}

update_prompt() {
  local arrow_style jj_segment user_segment first_left first_plain rendered_first_line sent_at cols pad_count padding
  arrow_style="$(prompt_arrow_style)"
  jj_segment="$(jj_prompt)"
  user_segment="$(prompt_user)"
  prompt_path_segments
  first_left="${user_segment}@%m  ${__prompt_path_prompt}${jj_segment}"
  first_plain="${user_segment}@%m  ${__prompt_path_plain//\%/%%}${jj_segment}"
  rendered_first_line="${(%)first_plain}"
  __prompt_first_line_cols="${#rendered_first_line}"

  sent_at="$(date '+%Y-%m-%d %H:%M:%S')"
  cols="${COLUMNS:-80}"
  (( __prompt_time_col = cols - ${#sent_at} + 1 ))
  (( __prompt_time_col < __prompt_first_line_cols + 2 )) && __prompt_time_col=$((__prompt_first_line_cols + 2))
  (( pad_count = __prompt_time_col - __prompt_first_line_cols - 1 ))
  padding="${(l:${pad_count}:: :)}"

  PS1="%F{245}${first_left}${padding}${sent_at}%f"$'\n'"%B${arrow_style}❯%f%b "
  RPROMPT=""
}

_prompt_accept_line() {
  local sent_at col up input_prompt_cols
  sent_at="$(date '+%Y-%m-%d %H:%M:%S')"

  # Stamp the timestamp onto the first prompt line when the command is sent.
  # RPROMPT appears on the editing line for multiline prompts, so draw this
  # directly at the right edge one visual prompt line above the command.
  input_prompt_cols=2
  (( up = (input_prompt_cols + CURSOR) / ${COLUMNS:-80} + 1 ))
  col="$__prompt_time_col"

  printf '\033[s\033[%dA\033[%dG\033[38;5;245m%s\033[0m\033[u' \
    "$up" "$col" "$sent_at"
  zle .accept-line
}

_prompt_spacing_precmd() {
  if (( __prompt_spacing_ran_command )); then
    print ""
    __prompt_spacing_ran_command=0
  fi
  update_prompt
}

_prompt_spacing_preexec() {
  case "$1" in
    clear|clear\ *|reset|reset\ *)
      __prompt_spacing_ran_command=0
      return
      ;;
  esac
  __prompt_spacing_ran_command=1
}

add-zsh-hook precmd _prompt_spacing_precmd
add-zsh-hook preexec _prompt_spacing_preexec
zle -N accept-line _prompt_accept_line

jj_prompt() {
  local tmp done pid output waited
  tmp="${TMPDIR:-/tmp}/zsh-jj-prompt.$$.$RANDOM"
  done="${tmp}.done"

  ( _jj_prompt_info >| "$tmp"; : >| "$done" ) &
  pid=$!

  for waited in {1..10}; do
    if [[ -e "$done" ]]; then
      wait "$pid" 2>/dev/null
      output="$(<"$tmp")"
      rm -f "$tmp" "$done"
      [[ -n "$output" ]] && print -r -- "$output"
      return
    fi
    sleep 0.02
  done

  if [[ -e "$done" ]]; then
    wait "$pid" 2>/dev/null
    output="$(<"$tmp")"
    [[ -n "$output" ]] && print -r -- "$output"
  else
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    print -r -- "  [...]"
  fi
  rm -f "$tmp" "$done"
}

_jj_prompt_info() {
  local stat summary
  local added=0 removed=0

  stat="$(jj --no-pager --color=never --quiet diff --stat 2>/dev/null)" || return
  summary="${${(f)stat}[-1]}"

  [[ "$summary" =~ '([0-9]+) insertion' ]] && added="$match[1]"
  [[ "$summary" =~ '([0-9]+) deletion' ]] && removed="$match[1]"

  if (( added > 0 || removed > 0 )); then
    printf '  +%d -%d' "$added" "$removed"
  else
    printf '  ±0'
  fi
}

setopt PROMPT_SUBST
update_prompt
