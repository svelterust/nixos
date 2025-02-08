export DIRENV_LOG_FORMAT=
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }"'echo -ne "\033]0;${HOSTNAME}:${PWD}\007"'

# variables
export PATH="$PATH:$HOME/.cargo/bin:$HOME/.bun/bin"
export LAUNCH_EDITOR="$HOME/.scripts/zed.sh"
export PLUG_EDITOR="zed://file/__FILE__:__LINE__"
export TERM="xterm-256color"
export OPENAI_API_KEY="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"

# aider
alias ai="aider --architect --model openrouter/deepseek/deepseek-r1 --editor-model openrouter/anthropic/claude-3.5-sonnet --api-key openrouter=$OPENAI_API_KEY"

# autojump
eval "$(zoxide init bash --cmd e)"
