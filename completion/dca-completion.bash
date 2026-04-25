#!/usr/bin/env bash
# shellcheck disable=SC2207
#
# bash completion for dca
# Source this file to enable tab completion for the dca command
#
# Installation:
#   Temporary (current session):
#     source /path/to/completion/dca-completion.bash
#
#   Permanent (add to ~/.bashrc):
#     source /path/to/dca/completion/dca-completion.bash
#
#   Or copy to bash completions directory:
#     cp /path/to/completion/dca-completion.bash /usr/local/etc/bash_completion.d/dca
#

_dca() {
  local cur words cword
  COMPREPLY=()

  cur="${COMP_WORDS[COMP_CWORD]}"
  words=("${COMP_WORDS[@]}")
  cword=${COMP_CWORD}

  # First argument after 'dca' - complete subcommands
  if [[ $cword -eq 1 ]]; then
    if [[ "$cur" == -* ]]; then
      COMPREPLY=($(compgen -W "-h --help help" -- "$cur"))
    else
      COMPREPLY=($(compgen -W "fork code devcontainer config" -- "$cur"))
    fi
    return 0
  fi

  # Handle subcommands
  local subcmd="${words[1]}"

  case "$subcmd" in
    fork)
      # 'dca fork' subcommand
      if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
      else
        # Positional arguments: <ref-repo> <target>
        # Enable path completion
        _filedir -d
      fi
      ;;
    code)
      # 'dca code' subcommand
      if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
      else
        # One argument: directory path
        _filedir -d
      fi
      ;;
    devcontainer)
      # 'dca devcontainer' subcommand
      if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
      else
        # First positional argument: directory path
        _filedir -d
      fi
      ;;
    config)
      # 'dca config' subcommand
      if [[ $cword -eq 2 ]]; then
        if [[ "$cur" == -* ]]; then
          COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
        else
          COMPREPLY=($(compgen -W "import import-vscode import-cursor show clear" -- "$cur"))
        fi
      elif [[ $cword -eq 3 && "${words[2]}" == "import" ]]; then
        # 'dca config import' takes a file argument
        _filedir
      fi
      ;;
  esac
}

complete -o bashdefault -o default -o nospace -F _dca dca
