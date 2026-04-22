#compdef push-to-phone
# zsh completion for push-to-phone
#
# Install (one of):
#   Copy to a dir in $fpath and restart zsh, OR
#   source completions/push-to-phone.zsh

_push_to_phone() {
  local -a subcommands flags priorities
  subcommands=(
    'wrap:run a command and notify on completion'
    'doctor:sanity-check setup and send a test ping'
    'test:alias for doctor'
    'help:show help'
    'version:show version'
  )
  priorities=(min low default high urgent 1 2 3 4 5)

  _arguments -C \
    '1:subcommand or flag:->first' \
    '(-t --title)'{-t,--title}'[notification title]:title:' \
    '(-m --message)'{-m,--message}'[message body]:message:' \
    '(-p --priority)'{-p,--priority}'[priority]:level:(min low default high urgent 1 2 3 4 5)' \
    '--tag[comma-separated ntfy tags]:tags:' \
    '--tags[comma-separated ntfy tags]:tags:' \
    '(-a --attach)'{-a,--attach}'[file to upload]:file:_files' \
    '--at[scheduled delivery time]:time:' \
    '--in[deliver after delay]:duration:' \
    '(-M --markdown)'{-M,--markdown}'[render body as markdown]' \
    '--copy[attach copy-to-clipboard action]:value:' \
    '(-b --batch)'{-b,--batch}'[batch mode, URLs on stdin]' \
    '(-n --dry-run)'{-n,--dry-run}'[do not actually send]' \
    '(-v --verbose)'{-v,--verbose}'[print success line]' \
    '--token[bearer token]:token:' \
    '--server[ntfy server URL]:url:' \
    '--topic[ntfy topic]:topic:' \
    '*:url:_urls' \
    && return 0

  case "$state" in
    first) _describe -t subcommands 'subcommand' subcommands ;;
  esac
}

compdef _push_to_phone push-to-phone
