if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g -x fish_greeting ''
end

starship init fish | source

eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)

zoxide init fish | source
echo 'mise activate fish | source' >>~/.config/fish/config.fish

function storePathForWindowsTerminal --on-variable PWD
    if test -n "$WT_SESSION"
        printf "\e]9;9;%s\e\\" (wslpath -w "$PWD")
    end
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# homebrew
set --export HOMEBREW_NO_AUTO_UPDATE 1
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
mise activate fish | source
