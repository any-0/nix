autoload -Uz add-zsh-hook

typeset -g __prompt_spacing_ran_command=0

_prompt_spacing_precmd() {
  if (( __prompt_spacing_ran_command )); then
    print ""
    __prompt_spacing_ran_command=0
  fi
}

_prompt_spacing_preexec() {
  case "$1" in
    clear|clear\ *|reset|reset\ *)
      __prompt_spacing_ran_command=0
      return
      ;;
  esac
  __prompt_spacing_ran_command=1
  print ""
}

add-zsh-hook precmd _prompt_spacing_precmd
add-zsh-hook preexec _prompt_spacing_preexec

git_prompt() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

  local changes numstat line x y add del
  local staged=0 unstaged=0 untracked=0
  local added=0 removed=0
  local -a segments

  changes="$(git status --porcelain 2>/dev/null)"
  numstat="$(
    git diff --numstat 2>/dev/null
    git diff --cached --numstat 2>/dev/null
  )"

  while IFS=$'\t' read -r add del _; do
    [[ "$add" == <-> ]] && ((added += add))
    [[ "$del" == <-> ]] && ((removed += del))
  done <<< "$numstat"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    if [[ "$line" == '?? '* ]]; then
      ((untracked++))
      continue
    fi

    x="${line[1,1]}"
    y="${line[2,2]}"
    [[ "$x" != " " ]] && ((staged++))
    [[ "$y" != " " ]] && ((unstaged++))
  done <<< "$changes"

  segments+=("+${added} -${removed}")
  ((staged > 0)) && segments+=("S:${staged}")
  ((unstaged > 0)) && segments+=("M:${unstaged}")
  ((untracked > 0)) && segments+=("U:${untracked}")
  printf '  [%s]' "${(j: :)segments}"
}

setopt PROMPT_SUBST
PS1=$'%F{245}%n@%m  [%~]$(git_prompt)%f\n%B%F{39}❯%f%b '
