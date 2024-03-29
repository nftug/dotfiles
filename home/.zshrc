#
# ~/.zshrc
#

function tmux_start () {
    tmux list-sessions > /dev/null 2>/dev/null
    [[ ! $? -eq 0 ]] && tmux new-session -s 0 -d
    
    # Start a tmux session with detaching all other clients. Only for local use.
    if [ -n "$OPEN_TMUX" ]; then
        exec tmux a -d -t 0
    else
        tmux a -d -t 0
    fi
}

function kill_detached_sessions () {
    sessions=$(tmux list-sessions -F '#{session_attached} #{session_id}' | awk '/^0/{print $2}')
    if [ -n "$sessions" ]; then
        n=`echo "$sessions" | wc -l`
        echo -n "$n sessions are being detached. Are you sure to kill them all? (y/N): "
        if read -q; then
            echo
            echo "$sessions" | xargs -n 1 tmux kill-session -t
        else
            echo
            echo "Aborted."
        fi
    else
        echo "There is no detached session."
        
    fi
}

if [[ -z "$TMUX" ]] && [[ -n "$OPEN_TMUX" ]]; then
    tmux_start
fi

export PATH=$PATH:$HOME/bin:$HOME/perl5/bin:$HOME/.local/bin:/opt/android-sdk/tools/bin:/opt/homebrew/bin
export PERL_CPANM_OPT="--local-lib=~/perl5"
export PERL5LIB=$HOME/perl5/lib/perl5:$PERL5LIB;

export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000

UNAME=`uname`

setopt hist_ignore_dups
setopt EXTENDED_HISTORY
setopt +o nomatch

bindkey -e
bindkey "^[[3~" delete-char
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line
bindkey "\e[1;3C" forward-word
bindkey "\e[1;3D" backward-word
bindkey "\e[1;5C" forward-word
bindkey "\e[1;5D" backward-word

stty intr '^C'
stty eof '^D'

#autoload predict-on
#bindkey '^X^P' predict-on
#bindkey '^O' predict-off
#zstyle ':predict' verbose true

function powerline_precmd() {
    PS1="$(powerline-go -error $? -modules cwd,git,root -cwd-mode dironly -shell zsh)"
}

function install_powerline_precmd() {
    for s in "${precmd_functions[@]}"; do
        if [ "$s" = "powerline_precmd" ]; then
            return
        fi
    done
    precmd_functions+=(powerline_precmd)
}

if [ "$TERM" != "linux" ] && [ `which powerline-go` ]; then
    install_powerline_precmd
fi

vterm_printf(){
    if [ -n "$TMUX" ]; then
        printf "\ePtmux;\e\e]%s\007\e\\" "$1"
        elif [ "${TERM%%-*}" = "screen" ]; then
        printf "\eP\e]%s\007\e\\" "$1"
    else
        printf "\e]%s\e\\" "$1"
    fi
}

vterm_prompt_end() {
    vterm_printf "51;A$(whoami)@$(hostname):$(pwd)";
}
setopt PROMPT_SUBST
PROMPT=$PROMPT'%{$(vterm_prompt_end)%}'

if [[ -n "$XDG_SESSION_TYPE" ]]; then
    export BROWSER="xdg-open"
    elif [[ $UNAME == "Darwin" ]]; then
    export BROWSER="open"
    alias emacs='/Applications/Emacs.app/Contents/MacOS/Emacs'
fi

if [ $TERM == linux ]; then
    export EDITOR='nano'
else
    export EDITOR='code'
fi

export SDCV_HISTSIZE=10000

# alias and functions

alias ls=lsd
alias e='ecl.sh -t'
alias ec='ecl.sh'
# alias o2pall='for file in *.org; do emacsclient -e "(find-file \"$file\")" -e "(org-latex-export-to-pdf)";  done'
# alias top='htop'
alias t='tmux'
#alias neofetch='neofetch --w3m --source=~/Pictures --package_managers off'

function sudoe() {
    $HOME/bin/ecl.sh -t /sudo::$(readlink -f $1)
}

function sudoec() {
    $HOME/bin/ecl.sh /sudo::$(readlink -f $1)
}

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit ice wait'0'

zinit light-mode for \
zdharma-continuum/z-a-rust \
zdharma-continuum/z-a-as-monitor \
zdharma-continuum/z-a-patch-dl \
zdharma-continuum/z-a-bin-gem-node

### End of Zinit's installer chunk

zinit ice wait'0'
zinit wait lucid light-mode for \
atinit"zicompinit; zicdreplay" \
zdharma-continuum/fast-syntax-highlighting \
atload"_zsh_autosuggest_start" \
zsh-users/zsh-autosuggestions \
blockf atpull'zinit creinstall -q .' \
zsh-users/zsh-completions

zstyle ':completion:*' list-colors di=34 ln=35 ex=31
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' insert-tab false

if [ $TERM != linux ]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
else
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=6'
fi

ZSH_AUTOSUGGEST_USE_ASYNC=y
# ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^ ' autosuggest-accept
bindkey '^ ' end-of-line

if [[ -n "$XDG_SESSION_TYPE" ]] || [[ $UNAME == "Darwin" ]]; then
    zinit ice wait'0'
    zinit light-mode for marzocchi/zsh-notify
    zstyle ':notify:*' error-title "Command failed (in #{time_elapsed} seconds)"
    zstyle ':notify:*' success-title "Command finished (in #{time_elapsed} seconds)"
    zstyle ':notify:*' error-icon "dialog-error"
    zstyle ':notify:*' success-icon "terminal"
    zstyle ':notify:*' command-complete-timeout 30
    zstyle ':notify:*' expire-time 10000
    zstyle ':notify:*' always-check-active-window yes
fi

autoload -Uz add-zsh-hook

if [[ $TERM != "linux" ]]; then
    # https://int128.hatenablog.com/entry/2017/01/22/005915
    function _window_title_cmd () {
        local pwd="${PWD/~HOME/~}"
        print -n "\e]0;"
        print -n "${pwd##*/}@${HOST%%.*}"
        print -n "\a"
    }
    
    function _window_title_exec () {
        local pwd="${PWD/~HOME/~}"
        print -n "\e]0;"
        print -n "${1%% *}:${pwd##*/}@${HOST%%.*}"
        print -n "\a"
    }
    
    add-zsh-hook precmd _window_title_cmd
    add-zsh-hook preexec _window_title_exec
    
    if [[ $UNAME == "Linux" ]]; then
        alias _copy='xsel -i -b'
        alias _paste='xsel -o -b'
        elif [[ $UNAME == "Darwin" ]]; then
        alias _copy='pbcopy'
        alias _paste='pbpaste'
    fi
    
    function copy-line-as-kill() {
        zle kill-line
        print -rn $CUTBUFFER | _copy
    }
    zle -N copy-line-as-kill
    bindkey '^k' copy-line-as-kill
    
    function paste-as-yank() {
        CUTBUFFER=$(_paste </dev/null)
        zle yank
    }
    zle -N paste-as-yank
    bindkey "^y" paste-as-yank
fi

# setopt IGNOREEOF
