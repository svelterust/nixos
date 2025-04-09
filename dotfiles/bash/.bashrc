export DIRENV_LOG_FORMAT=
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }"'echo -ne "\033]0;${HOSTNAME}:${PWD}\007"'

# variables
export PATH="$HOME/.cargo/bin:$HOME/.bun/bin:$PATH"
export PLUG_EDITOR="zed://file/__FILE__:__LINE__"
export VISUAL="$HOME/.config/zed/zed.sh"
export EDITOR="$HOME/.config/zed/zed.sh"
export ERL_AFLAGS="-kernel shell_history enabled"
export TERM="xterm-256color"

# autojump
eval "$(zoxide init bash --cmd e)"
