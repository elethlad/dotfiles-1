#!/usr/bin/env bash

export MANPAGER="bash -c \"col -b | vim -Nu NONE -c 'runtime macros/less.vim' -c 'setf man' -\""
export EDITOR='vim'
export HISTFILESIZE=500000
export HISTSIZE=100000
unset GREP_OPTIONS
stty -ixon

has() {
  local verbose
  verbose=false
  if [[ $1 = -v ]]; then
    verbose=true
    shift
  fi
  for c; do c="${c%% *}"
    if ! command -v "$c" &> /dev/null; then
      [[ "$verbose" = true ]] && err "$c not found"
      return 1
    fi
  done
}

has fortune && fortune -ae

ask() {
  read -r -n1 -p "$* " ans
  echo
  [[ ${ans^} = Y* ]]
}

declare -A colors
colors[red]=$(tput setaf 1)
colors[green]=$(tput setaf 2)
colors[blue]=$(tput setaf 4)
colors[reset]=$(tput sgr0)

color() {
  local c
  c="$1"
  shift
  printf '%s' "${colors[$c]}"
  printf '%s\n' "$@"
  printf '%s' "${colors[reset]}"
}

err() { color red "$@" >2; }

if [[ -f /etc/debian_version ]]; then
  for h in 'apt' 'aptitude' 'apt-get'; do
    if has $h; then
      alias canhaz="sudo $h install "
      alias updupg="sudo $h upgrade "
      pkgrm() { sudo apt-get purge "$@" && sudo apt-get autoremove ;}
      break
    fi
  done
  unset h
  alias unlock-dpkg="sudo fuser -vki /var/lib/dpkg/lock; sudo dpkg --configure -a"
elif [[ -f /etc/arch-release ]]; then
  for h in 'pacaur' 'yaourt' 'pacman'; do
    if has $h; then
      [[ "$h" = "pacman" ]] && h="sudo pacman"
      alias canhaz="$h -S "
      if has pkgup; then
        updupg() { upglibs; sudo pacman -Sy && pkgup ;}
      else
        alias updupg="$h -Syu "
      fi
      break
    fi
  done
  unset h
  has pkgrm || alias pkgrm='sudo pacman -Rsu '
elif [[ -f /etc/redhat-release ]]; then
  alias canhaz='sudo dnf install '
elif [[ -f /etc/gentoo-release ]]; then
  alias canhaz='sudo emerge -av '
fi

upglibs() {
  txs "gitup -F -p8 ~/.oh-my-zsh ~/.zsh/plugins ~/.vim/bundle ~/.emacs.d ~/.fzf ~/.tmux/plugins; bash -c 'read -r -p \"Done! Press any key to close.\" -n1'"
}

alias ..='cd ..'
alias ...='cd ../..'

alias cp='cp -v '
alias mv='mv -v '
alias rm='rm -v '
alias ln='ln -v '
alias curl='curl -v '
alias chown='chown -v '
alias chmod='chmod -v '
alias rename='rename -v '
alias ls='ls -Fh --color --group-directories-first '
alias l='ls -lgo '
alias lt='l -t'
alias lx='l -X'
alias la='l -A '
alias lax='la -X'
alias lat='la -t'
alias grep='grep --exclude-dir={.bzr,CVS,.git,.hg,.svn,node_modules,bower_components,jspm_packages} --color=auto -P '
alias historygrep='history | command grep -vF "history" | grep '
alias xargs="tr '\n' '\0' | xargs -0 -I% "
alias shuf1='shuf -n1'
has cdu && alias cdu='cdu -isdhD '
has rsync && alias rsync='rsync -v --progress --stats '
has lein && alias lein='rlwrap lein '
has pkgsearch && alias pkgs='FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --reverse --preview-window=bottom:hidden" pkgsearch '
has pip && alias pipi='pip install --user --upgrade '

# {{{ git aliases
if has git; then
  alias g='git '
  alias ga='git add '
  alias gap='git add -p '
  alias gb='git branch '
  alias gc='git commit -v '
  alias gcm='git commit -m '
  alias gco='git checkout '
  alias gl='git pull '
  alias gp='git push '
  alias gst='git status --untracked-files=no '
  alias gm='git merge --no-ff '
  alias gd='git diff '
  gcl() {
    local dir repo
    if [[ -z "$1" ]]; then
      echo 'no arguments specified'
      return 1
    fi
    case "$1" in
      http*|https*|git*|ssh*) repo="$1" ;;
      *) repo="https://github.com/$1" ;;
    esac
    shift
    if [[ -n "$1" && "$1" != -* ]]; then
      dir="$1"
      shift
    else
      dir="${repo##*/}"
      dir="${dir/%.git}"
    fi
    git clone "$repo" "$@"
    [[ -d "$dir" ]] && cd "$dir"
  }
  gsb() {
    if [[ -z "$1" ]]; then
      err 'No branch name specified'
      return 1
    fi
    git stash
    git stash branch "$1"
  }
fi
# }}}

cd() {
  local dir
  if [[ -z "$@" ]]; then
    builtin cd ~ && ls
  else
    dir="$1"
    shift
    builtin cd "$dir" && ls "$@";
  fi
}

mkd() { mkdir -p "$@" && cd "$1" ;}

trash() {
  for arg in "$@"; do
    [[ "$arg" = -* ]] && shift
  done
  mkdir -vp ~/.trash
  mv -vt ~/.trash "$@"
}

cat() {
  if [[ -t 1 ]]; then
    more "$@" | LESS=-~FEXR less
  else
    command cat "$@"
  fi
}

help() { bash -c "help $*" ;}

bground() { ("$@" &> /dev/null &) ;}
restart() { pkill -x "$1"; bground "$@" ;}

function in {
  local t
  t=( "$1" "$2" )
  shift 2
  at now + "${t[@]}" <<< "$*"
}

decide() {
  local args
  args=( "$@" )
  (( $# < 2 )) && args=( yes no )
  printf '%s\n' "${args[@]}" | shuf -n1
}

ed() { command ed -p: "$@" ;} # https://sanctum.geek.nz/arabesque/actually-using-ed/

txs() {
  local nested opts
  opts=( -d )
  for a in "$@"; do
    case $a in
      -N) nested=1 ; shift ;;
      -*)  opts+=( "$1" ) ; shift ;;
    esac
  done
  cmd="$*"
  if [[ -n "$nested" ]]; then
    cmd="TMUX='' tmux new \; source ~/dotfiles/tmux.alt.conf \; send-keys '$cmd' C-m"
  fi
  tmux split-window "${opts[@]}" "$cmd"
}

sprunge() { more -- "$@" | command curl -sF 'sprunge=<-' http://sprunge.us ;}

pgrep() { ps aux | command grep -iP "$*" | command grep -ivF grep ;}

textImage() {
  convert -background white -fill black -size 500x500 -gravity Center -font Droid-Sans-Regular caption:"$1" "$2" &&
  optipng "$2" &&
  qiv "$2"
}

burnusb() {
  sudo dd if="$1" of="$2" bs=4M conv=sync status=progress
  sync
  ding 'burnusb' 'done'
}

changeroot() {
  emulate -L bash
  sudo cp -L /etc/resolv.conf "$1"/etc/resolv.conf
  sudo mount -t proc proc "$1"/proc
  sudo mount -t sysfs sys "$1"/sys
  # sudo mount -o bind /dev "$1"/dev
  # sudo mount -t devpts pts "$1"/dev/pts/
  sudo chroot "$1"/ /bin/bash
  ask "unmount $1? " && (
    sudo umount -l "$1"
    sudo chroot /
  )
  emulate -L zsh
}

extract() {
  if [[ -f "$1" ]] ; then
    case "$1" in
      *.tar.bz2)   tar xvjf "$1"  ;;
      *.tar.gz)    tar xvzf "$1"  ;;
      *.bz2)       bunzip2 "$1"   ;;
      *.rar)       unrar x "$1"   ;;
      *.gz)        gunzip "$1"    ;;
      *.tar)       tar xvf "$1"   ;;
      *.tbz2)      tar xvjf "$1"  ;;
      *.tgz)       tar xvzf "$1"  ;;
      *.zip)       unzip "$1"     ;;
      *.Z)         uncompress "$1";;
      *.7z)        7z x "$1"      ;;
      *)           echo "'$1' cannot be extracted via >extract<" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

curltar() {
  case "$1" in
    *.tar.bz2)   command curl -L "$1" | tar xvjf   -  ;;
    *.tar.gz)    command curl -L "$1" | tar xvzf   -  ;;
    *.bz2)       command curl -L "$1" | bunzip2    -  ;;
    *.tar)       command curl -L "$1" | tar xvf    -  ;;
    *.tbz2)      command curl -L "$1" | tar xvjf   -  ;;
    *.tgz)       command curl -L "$1" | tar xvzf   -  ;;
    *)           command curl -LO "$1"
  esac
}

whitenoise() { aplay -c 2 -f S16_LE -r 44100 /dev/urandom ;}

weather() { command curl -s http://wttr.in/"${*:-galveston texas}"; }

if has synclient vipe; then
  synclient() {
    if command synclient -l &> /dev/null; then
      if (( $# > 0 )); then
        command synclient "$@"
      else
        command synclient $(command synclient | vipe | sed '1d;s/ //g')
      fi
    else
      command synclient
    fi
  }
fi

if has fzf; then
  umnt() {
    device=$(mount -l | awk '$5 !~ /gvfsd|debugfs|hugetlbfs|mqueue|tracefs|devpts|securityfs|pstore|sysfs|proc|autofs|cgroup|fusect|tmpfs/{print $1, $3, $5, $6}' | column -t | fzf --inline-info | awk '{print $2}')
    [[ -n "$device" ]] && sudo umount -l "$device"
  }

  nvmuse() {
    version=$(nvm ls | fzf --inline-info --ansi | grep -oP '(system|(iojs-)?v\d+\.\d+\.\d+)')
    [[ -n $version ]] && nvm use "$version"
  }

  nvminstall() {
    version=$(nvm ls-remote | fzf --inline-info --ansi --tac | grep -oP '(system|(iojs-)?v\d+\.\d+\.\d+)')
    [[ -n $version ]] && nvm install "$version"
  }

  has npmsearch && alias npms='npmsearch '
fi

[[ -s ~/.nvm/nvm.sh ]] && loadnvm() {
  if ! has nvm; then
    echo 'loading nvm...'
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  else
    echo 'nvm already loaded!'
  fi
}

[[ -s ~/.perlbrew/etc/bashrc ]] && loadperlbrew() {
  source ~/.perlbrew/etc/bashrc
}

if has rlwrap; then
  node() {
    if (( $# > 0 )); then
      command node "$@"
    else
      if ! type -p node &> /dev/null && has loadnvm; then
        loadnvm
      fi
      NODE_NO_READLINE=1 rlwrap -m -H ~/.node_repl_history -pblue node
    fi
  }

  if has guile; then
    guile() {
      if (( $# > 0 )); then
         command guile "$@"
      else
        rlwrap guile
      fi
    }
  fi

  if has clojure; then
     clojure() {
      if (( $# > 0 )); then
        command clojure "$@"
      else
        rlwrap clojure
      fi
    }
  fi
fi

if [[ -e /opt/closure/compiler.jar ]]; then
  closure() {
    java -jar /opt/closure/compiler.jar "$@"
  }
fi

has VBoxManage && vm() {
  VBoxManage startvm "$1" --type headless || return
  echo 'starting ssh...'
  ssh "$1"
  VBoxManage controlvm "$1" poweroff
}

if has api; then
  gitlab_get_repoid() {
    api gitlab get projects | jq ".[] | select(.name == \"$1\") | .id"
  }

  gitlab_make_public() {
    local repoid
    repoid=$(gitlab_get_repoid "$1")
    api gitlab put "projects/$repoid" -d 'visibility_level=20&issues_enabled=true&wiki_enabled=true'
  }

  gitlab_build_list() {
    local repoid
    repoid=$(gitlab_get_repoid "$1")
    api gitlab get "projects/$repoid/builds" -d 'scope=running' | jq '.'
  }
fi

has boil && boil() {
  loadperlbrew
  command boil "$@" && while getopts 'n:' x; do
    case "$x" in
      n) cd ~/build/"$OPTARG"
    esac
  done
}

make() {
  if [[ "$*" == 'me a sandwich'* ]]; then
    shift 3
    ./configure "$@" && command make -j $(( $(nproc) - 1))
  else
    command make "$@"
  fi
}

diffplugins() {
  if (( $# < 1 )); then
    err 'need a file or url'
    return 1
  fi
  if [[ $1 = http* ]]; then
    has -v curl || return
    file=$(command curl -s "$1")
  elif [[ -r $1 ]]; then
    file=$(< "$1")
  else
    err "$1 is not a readable file or url"
    return 1
  fi
  diff -u <(command grep -Po "Plug '[^']+'" ~/.vimrc | sort) \
    <(command grep -Po "Plug '[^']+'" <<< "$file" | sort) |
    awk -F \' '/^\+/{printf "%s/%s\n", "https://github.com", $2}'
}

# vim:ft=sh:
