export DIRENV_LOG_FORMAT=
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }"'echo -ne "\033]0;${HOSTNAME}:${PWD}\007"'

vterm_printf() {
    if [ -n "$TMUX" ] && ([ "${TERM%%-*}" = "tmux" ] || [ "${TERM%%-*}" = "screen" ]); then
        # Tell tmux to pass the escape sequences through
        printf "\ePtmux;\e\e]%s\007\e\\" "$1"
    elif [ "${TERM%%-*}" = "screen" ]; then
        # GNU screen (screen, screen-256color, screen-256color-bce)
        printf "\eP\e]%s\007\e\\" "$1"
    else
        printf "\e]%s\e\\" "$1"
    fi
}

vterm_prompt_end(){
    vterm_printf "51;A$(whoami)@$(hostname):$(pwd)"
}
PS1=$PS1'\[$(vterm_prompt_end)\]'

# variables
export PATH="$PATH:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/.local/share/gem/ruby/3.3.0/bin"
export BROWSER="chromium"
export VISUAL="zed-fhs"
export EDITOR="zed-fhs"
export LAUNCH_EDITOR="zed"
