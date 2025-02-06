if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g -x fish_greeting ''
end

# load enviroments
# envload ~/.env.secrets
eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# homebrew
set --export HOMEBREW_NO_AUTO_UPDATE 1

# rust
source "$HOME/.cargo/env.fish"

zoxide init fish | source # initialize zoxide alias 'z'
mise activate fish | source # initialize mise-en-place alias 'mise'
starship init fish | source # initialize starship

# function to correct initialize wsl and windows terminal 
function storePathForWindowsTerminal --on-variable PWD
    if test -n "$WT_SESSION"
        printf "\e]9;9;%s\e\\" (wslpath -w "$PWD")
    end
end
