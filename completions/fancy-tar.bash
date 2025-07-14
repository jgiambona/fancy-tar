#!/bin/bash
_fancy_tar() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  opts="-o -n -s -x -t --tree --no-recursion --hash --encrypt= --recipient --password --key-file --zip --version --help --print-filename --force -f --verbose"

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

  # Add additional completion options
  case "${cur}" in
    --output=*|-o=*)
      _filedir
      COMPREPLY+=( $(compgen -W "*.parts.txt" -- ${cur#*=}) )
      return
      ;;
    --compression=*)
      COMPREPLY=($(compgen -W "0 1 2 3 4 5 6 7 8 9" -- "${cur#*=}"))
      return
      ;;
    --use=*)
      COMPREPLY=($(compgen -W "gzip pigz bzip2 pbzip2 lbzip2 xz pxz" -- "${cur#*=}"))
      return
      ;;
    --split-size=*)
      COMPREPLY=($(compgen -W "100M 500M 1G 2G 5G" -- "${cur#*=}"))
      return
      ;;
    --encrypt=*)
      COMPREPLY=($(compgen -W "gpg openssl" -- "${cur#*=}"))
      return
      ;;
    --recipient=*)
      COMPREPLY=($(compgen -W "$(gpg --list-keys --with-colons | awk -F: '/^pub:/ {print $5}')" -- "${cur#*=}"))
      # Can be specified multiple times
      return
      ;;
    --password=*)
      return
      ;;
    --output|-o)
      _filedir
      return
      ;;
    --compression)
      COMPREPLY=($(compgen -W "0 1 2 3 4 5 6 7 8 9" -- "$cur"))
      return
      ;;
    --use)
      COMPREPLY=($(compgen -W "gzip pigz bzip2 pbzip2 lbzip2 xz pxz" -- "$cur"))
      return
      ;;
    --split-size)
      COMPREPLY=($(compgen -W "100M 500M 1G 2G 5G" -- "$cur"))
      return
      ;;
    --encrypt)
      COMPREPLY=($(compgen -W "gpg openssl" -- "$cur"))
      return
      ;;
    --recipient)
      COMPREPLY=($(compgen -W "$(gpg --list-keys --with-colons | awk -F: '/^pub:/ {print $5}')" -- "$cur"))
      # Can be specified multiple times
      return
      ;;
    --password)
      return
      ;;
    --key-file=*)
      _filedir
      return
      ;;
    --key-file)
      _filedir
      return
      ;;
    --help|-h)
      return
      ;;
    --version|-v)
      return
      ;;
    --self-test)
      return
      ;;
    --tree|-t)
      return
      ;;
    --no-recurse)
      return
      ;;
    --hash)
      return
      ;;
    --verify)
      return
      ;;
    --zip)
      return
      ;;
    --7z)
      return
      ;;
    --force|-f)
      return
      ;;
    --manifest=*)
      COMPREPLY=($(compgen -W "tree text csv csvhash" -- "${cur#*=}"))
      return
      ;;
    --manifest)
      COMPREPLY=( $(compgen -W "tree text csv csvhash" -- "$cur") )
      return 0
      ;;
    --exclude)
      _filedir
      return 0
      ;;
    --include)
      _filedir
      return 0
      ;;
    --files-from)
      _filedir
      return 0
      ;;
    --verbose)
      return 0
      ;;
    --)
      _filedir
      return
      ;;
    -*)
      COMPREPLY=($(compgen -W "--output -o --compression --use --split-size --encrypt --recipient --password --key-file --help -h --version -v --self-test --tree -t --no-recurse --hash --verify --zip --7z --force -f --verbose" -- "$cur"))
      return
      ;;
  esac
}
complete -F _fancy_tar fancy-tar fancytar ftar
