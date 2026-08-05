autoload -Uz add-zsh-hook

typeset -g __prompt_spacing_ran_command=0
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
  local arrow_style jj_segment user_segment first_line
  arrow_style="$(prompt_arrow_style)"
  jj_segment="$(jj_prompt)"
  user_segment="$(prompt_user)"
  prompt_path_segments
  first_line="${user_segment}@%m  ${__prompt_path_prompt}${jj_segment}"
  PS1="%F{245}${first_line}%f"$'\n'"%B${arrow_style}❯%f%b "
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

jj_prompt() {
  local stat summary rc
  local added=0 removed=0

  stat="$(timeout --kill-after=0.05s 0.2s jj --no-pager --color=never --quiet diff --stat 2>/dev/null)"
  rc=$?

  if (( rc == 124 || rc == 137 )); then
    print -r -- "  [...]"
    return
  fi
  (( rc == 0 )) || return

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
