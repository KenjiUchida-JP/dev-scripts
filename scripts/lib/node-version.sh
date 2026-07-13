#!/usr/bin/env bash
# Node.js version manager detection helpers (fnm / nvm)

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Load nvm if available
load_nvm() {
    # nvm is a shell function, not a binary, so we need to source it
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
        return 0
    elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
        # macOS Homebrew location
        source "/usr/local/opt/nvm/nvm.sh"
        return 0
    elif [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
        # macOS Apple Silicon Homebrew location
        source "/opt/homebrew/opt/nvm/nvm.sh"
        return 0
    fi
    return 1
}

# Check if nvm is available
nvm_available() {
    type nvm &>/dev/null
}

# Get installed Node versions via nvm
get_nvm_versions() {
    nvm ls --no-colors 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq
}

# Get latest LTS version available
get_nvm_lts_version() {
    nvm ls-remote --lts --no-colors 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1
}

# --------------------------------------------------
# fnm (Fast Node Manager) functions
# --------------------------------------------------

# Check if fnm is available
fnm_available() {
    command -v fnm &>/dev/null
}

# Get installed Node versions via fnm
get_fnm_versions() {
    fnm list 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq
}

# Get latest LTS version available via fnm
get_fnm_lts_version() {
    fnm ls-remote --lts 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1
}
