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

export PATH=$PATH:$HOME/bin:$HOME/perl5/bin:$HOME/.local/bin
export PERL_CPANM_OPT="--local-lib=~/perl5"
export PERL5LIB=$HOME/perl5/lib/perl5:$PERL5LIB;

export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000
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

if [ "$TERM" != "linux" ] && [ -f /bin/powerline-go ]; then
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


export BROWSER=/usr/bin/chromium
export EDITOR="$HOME/bin/ecl.sh"
# if [ $TERM != linux ]; then
#     export EDITOR='$HOME/bin/ecl.sh'
# else
#     export EDITOR='$HOME/bin/ecl.sh -t'
# fi

export SDCV_HISTSIZE=10000

# alias and functions

alias ls=lsd
alias e='ecl.sh -t'
alias ec='ecl.sh'
# alias o2pall='for file in *.org; do emacsclient -e "(find-file \"$file\")" -e "(org-latex-export-to-pdf)";  done'
# alias top='htop'
alias t='tmux'
#alias neofetch='neofetch --w3m --source=~/Pictures --package_managers off'

function picscale() {
    for f in $(find .  -maxdepth 1 -type f -name '*.JPG'); do
	convert $f -resize '50%' -crop '95%x95%+0+0' $f
    done
}

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
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
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
      zinit-zsh/z-a-rust \
      zinit-zsh/z-a-as-monitor \
      zinit-zsh/z-a-patch-dl \
      zinit-zsh/z-a-bin-gem-node

### End of Zinit's installer chunk

zinit ice wait'0'
zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
      zdharma/fast-syntax-highlighting \
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

if [[ -n "$DISPLAY" ]]; then
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

if [[ -n "$DISPLAY" ]]; then
   add-zsh-hook precmd _window_title_cmd
   add-zsh-hook preexec _window_title_exec
fi

if [[ -n "$DISPLAY" ]]; then
    function copy-line-as-kill() {
	zle kill-line
	print -rn $CUTBUFFER | xsel -i -b
    }
    zle -N copy-line-as-kill
    bindkey '^k' copy-line-as-kill

    function paste-as-yank() {
	CUTBUFFER=$(xsel -o -b </dev/null)
	zle yank
    }
    zle -N paste-as-yank
    bindkey "^y" paste-as-yank
fi
