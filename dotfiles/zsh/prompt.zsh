autoload -Uz add-zsh-hook

typeset -g __prompt_spacing_ran_command=0

prompt_arrow_color() {
  if direnv_active; then
    print "196"
  elif [[ -n "$IN_NIX_SHELL" ]]; then
    print "46"
  else
    print "39"
  fi
}

direnv_active() {
  [[ -n "$DIRENV_DIR" ]] || return 1

  direnv status --json 2>/dev/null | jq -e '
    .state.foundRC != null
    and .state.loadedRC != null
    and .state.foundRC.path == .state.loadedRC.path
    and .state.foundRC.allowed == 0
    and .state.loadedRC.allowed == 0
  ' >/dev/null
}

update_prompt() {
  local arrow_color git_segment
  arrow_color="$(prompt_arrow_color)"
  git_segment="$(git_prompt)"
  PS1="%F{245}%n@%m  [%~]${git_segment}%f"$'\n'"%B%F{${arrow_color}}❯%f%b "
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
  print ""
}

add-zsh-hook precmd _prompt_spacing_precmd
add-zsh-hook preexec _prompt_spacing_preexec

git_prompt() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

  local changes numstat line x y add del branch
  local staged=0 unstaged=0 untracked=0
  local added=0 removed=0
  local -a segments

  if command -v jj >/dev/null 2>&1 && jj root >/dev/null 2>&1; then
    branch="$(jj log -r 'heads(::@ & bookmarks())' --no-graph -T 'bookmarks.join(" ")' 2>/dev/null)"
    [[ -n "$branch" ]] || branch="$(jj log -r @ --no-graph -T 'change_id.short()' 2>/dev/null)"
  fi
  [[ -n "$branch" ]] || branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
  branch="${branch//\%/%%}"

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

  [[ -n "$branch" ]] && segments+=("${branch}")
  segments+=("+${added} -${removed}")
  ((staged > 0)) && segments+=("S:${staged}")
  ((unstaged > 0)) && segments+=("M:${unstaged}")
  ((untracked > 0)) && segments+=("U:${untracked}")
  printf '  [%s]' "${(j: :)segments}"
}

setopt PROMPT_SUBST
update_prompt
