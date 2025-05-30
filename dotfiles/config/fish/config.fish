if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g -x fish_greeting ''
end

# load enviroments
envload ~/.env.secrets
eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)

# asdf
if test -z $ASDF_DATA_DIR
    set _asdf_shims "$HOME/.asdf/shims"
else
    set _asdf_shims "$ASDF_DATA_DIR/shims"
end

# Do not use fish_add_path (added in Fish 3.2) because it
# potentially changes the order of items in PATH
if not contains $_asdf_shims $PATH
    set -gx --prepend PATH $_asdf_shims
end
set --erase _asdf_shims

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# homebrew
set --export HOMEBREW_NO_AUTO_UPDATE 1

# rust
source "$HOME/.cargo/env.fish"

zoxide init fish | source # initialize zoxide alias 'z'
starship init fish | source # initialize starship

# alias
alias dotdrop="dotdrop -p default -c '$HOME/.dotdrop/config.yaml'"
alias lt="eza -T"

# function to correct initialize wsl and windows terminal 
function storePathForWindowsTerminal --on-variable PWD
    if test -n "$WT_SESSION"
        printf "\e]9;9;%s\e\\" (wslpath -w "$PWD")
    end
end
