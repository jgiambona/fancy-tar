#!/bin/bash
_fancy_tar() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  opts="-o -n -s -x -h -t --tree --no-recursion --help"

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
}
complete -F _fancy_tar fancy-tar
