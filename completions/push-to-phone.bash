# bash completion for push-to-phone
#
# Install:
#   source completions/push-to-phone.bash
# or copy to: /usr/local/etc/bash_completion.d/push-to-phone
_push_to_phone() {
  local cur prev words cword
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local subcommands="wrap doctor test help version"
  local flags="-t --title -m --message -p --priority --tag --tags --attach -a
               --at --in -M --markdown --copy -b --batch -n --dry-run
               -v --verbose --token --server --topic -h --help"

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "$subcommands $flags" -- "$cur") )
    return 0
  fi

  case "$prev" in
    -p|--priority) COMPREPLY=( $(compgen -W "min low default high urgent 1 2 3 4 5" -- "$cur") ); return 0 ;;
    -a|--attach)   COMPREPLY=( $(compgen -f -- "$cur") ); return 0 ;;
    --at|--in)     COMPREPLY=( $(compgen -W "'30m' '1h' '2h' 'tomorrow 9am' 'tomorrow 6pm'" -- "$cur") ); return 0 ;;
  esac

  COMPREPLY=( $(compgen -W "$flags" -- "$cur") )
}
complete -F _push_to_phone push-to-phone
