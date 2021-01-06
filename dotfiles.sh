#!/bin/bash

DIR_DOTFILES="$HOME/.dotfiles"
REPO_HOME="$DIR_DOTFILES/home"
REPO_HOME_HOSTDEP="$DIR_DOTFILES/home_hostdep/$HOSTNAME"
REPO_ROOT="$DIR_DOTFILES/root"
REPO_ROOT_HOSTDEP="$DIR_DOTFILES/root_hostdep/$HOSTNAME"
SYNC_LOG="/tmp/dotfiles.log"
PKGLIST="$HOME/bin/pkglist.sh"

env_patch() {
    cd "${REPO_HOME}"
    for d in $(find -type f -name $HOSTNAME.diff -exec dirname {} \;| uniq); do
	cd "$d"
	patch $1 -p1 < $HOSTNAME.diff
	[ -f *.rej ] && rm *.rej
	[ -f *.orig ] && rm *.orig
	cd "${REPO_HOME}"
    done
}

link () {
    local opt='-s -n -f'
    [[ -n "$@" ]] && opt="${opt} $@"
    
    # ホームディレクトリ
    cd "${REPO_HOME}"
    for f in $(find -not -type d -and -not -name '*.diff' | sed "s/^\.\///"); do
        dirname=`dirname "$HOME"/"$f"`
        [ ! -d "${dirname}" ] && mkdir -p "${dirname}"
	ln ${opt} "${REPO_HOME}"/"$f" "$HOME"/"$f"
    done

    # ホームディレクトリ (ホスト別)
    if [ -d "${REPO_HOME_HOSTDEP}" ]; then
	cd "${REPO_HOME_HOSTDEP}"
	for f in $(find -not -type d -and -not -name '*.diff' | sed "s/^\.\///"); do
            dirname=`dirname "$HOME"/"$f"`
            [ ! -d "${dirname}" ] && mkdir -p "${dirname}"
	    ln ${opt} "${REPO_HOME_HOSTDEP}"/"$f" "$HOME"/"$f"
	done
    fi
    clean
}

elcomp() {
    # cd "$DIR_DOTFILES"
    # out_diff=$(git diff HEAD^)
    
    cd "$HOME/.emacs.d/"
    emacs -l ~/.emacs.d/init.el --batch --eval="(byte-recompile-directory \"$REPO_HOME/.emacs.d/\" 0)"
    
    if [ $? -eq 0 ]; then
	echo "Compile completed!" >&2
    else
	echo "Compile failed!" >&2
    fi
    mv $REPO_HOME/.emacs.d/*.elc $HOME/.emacs.d/
    
}

deploy() {
    getopts fn OPT
    
    cd "$DIR_DOTFILES"
    if [[ $OPT = 'f' ]]; then
	git fetch origin main
	git reset --hard origin/main
    fi
    
    git pull origin main
    if [ ! $? -eq 0 ]; then
	exit 1
    fi

    env_patch -R    
    link
    env_patch

    if [[ $OPT != 'n' ]]; then
	elcomp
    fi
}

deploy_root () {
    cd "$DIR_DOTFILES"
    git pull origin main

    cd "${REPO_ROOT}"
     for f in $(find -not -type d -and -not -name '*.diff' | sed "s/^\.\///"); do
        dirname=`dirname /"$f"`
        [ ! -d "${dirname}" ] && mkdir -p "${dirname}"
	sudo cp -r "${REPO_ROOT}"/"$f" /"$f"
     done

     if [ -d "${REPO_ROOT_HOSTDEP}" ]; then
	cd "${REPO_ROOT_HOSTDEP}"
	for f in $(find -not -type d -and -not -name '*.diff' | sed "s/^\.\///"); do
            dirname=`dirname /"$f"`
            [ ! -d "${dirname}" ] && mkdir -p "${dirname}"
	    sudo cp -r "${REPO_ROOT_HOSTDEP}"/"$f" /"$f"
	done
    fi
}

clean () {
    # 壊れているシンボリックリンクを削除
    find -L "$HOME/" -maxdepth 1 -type l -exec unlink {} \;
    find -L "$HOME/.config/" -type l -exec unlink {} \;
    find -L "$HOME/bin/" -type l -exec unlink {} \;
}

commit () {
    echo "Outputting package lists..."
    [ ! -d "$DIR_DOTFILES/pkglist/$HOSTNAME" ] && mkdir -p "$DIR_DOTFILES/pkglist/$HOSTNAME"
    $PKGLIST > "$DIR_DOTFILES/pkglist/$HOSTNAME/pkglist.txt"
    $PKGLIST -a > "$DIR_DOTFILES/pkglist/$HOSTNAME/pkglist_aur.txt"

    echo "Applying patches..."
    env_patch -R

    echo "Committing to git repository..."
    cd "$DIR_DOTFILES"
    git add -A
    git commit -m "Committed from $HOSTNAME"
    git push -u origin main
    
    env_patch
}

_sync()
{
    duration=$1
    [[ -z "$duration" ]] && duration=$((3600*3))
    
    while true; do
	# ip=`ip addr show | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | grep -o [0-9].* | tail -n 1`
	$0 deploy >>$SYNC_LOG 2>>$SYNC_LOG
	if [ $? -eq 0 ]; then
	    notify-send -t 5000 -i dialog-information "Dotfiles" "Synchronization succeeded."
	else
	    notify-send -i dialog-error "Dotfiles" "Synchronization failed."
	fi
	sleep $duration
    done
}

main() {
    case "$1" in
	"deploy" ) deploy $2 ;;
	"deploy_root" ) deploy_root ;;
	"link" ) link -v ;;
	"commit" ) commit ;;
	"clean" ) clean ;;
	"elcomp" ) elcomp ;;
	"sync" ) _sync $2 ;;
	* )
	    echo "Usage: $(basename $0) [command]"
	    echo
	    echo "Commands:"
	    echo
	    echo -e "  deploy\t Pull from the remote git repository and deploy dotfiles into home directory."
	    echo -e "  deploy_root\t Apply operations of deploying into root directory (sudo permission needed)."
	    echo -e "  link\t\t Deploy links of dotfiles without pulling from the git repository."
	    echo -e "  commit\t Commit changes to the git reposiory."
	    echo -e "        \t [-f forces to reset the local repository.]"
	    echo -e "        \t [-n prevents from compiling elisp files.]"
	    echo -e "  clean\t\t Clean broken symbolic link files."
	    echo -e "  elcomp\t Byte-compile newly updated elisp files."
	    echo -e "  sync\t\t Start sync daemon. Set duration time on an argument."
	    echo
	    ;;
    esac
}

main "$@"
