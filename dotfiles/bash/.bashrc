export DIRENV_LOG_FORMAT=
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }"'echo -ne "\033]0;${HOSTNAME}:${PWD}\007"'

# variables
export PATH="$PATH:$HOME/.cargo/bin:$HOME/.bun/bin"
export LAUNCH_EDITOR="$HOME/.scripts/zed.sh"
export PLUG_EDITOR="zed://file/__FILE__:__LINE__"
export TERM="xterm-256color"

# autojump
eval "$(zoxide init bash --cmd e)"
