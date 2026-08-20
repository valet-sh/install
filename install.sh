#!/usr/bin/env bash

################################################################################
# valet.sh cli
#
# Copyright: (C) 2025 TechDivision GmbH - All Rights Reserved
# Author: Philipp Dittert <p.dittert@techdivision.com>
################################################################################

# exit immediately if a command exits with a non-zero status
set -e

# define variables
VSH_NAME="valet.sh"
VSH_URL="https://valet.sh"
VSH_INSTALL_LOG="/tmp/valet-sh-install.log"
VSH_GITHUB_REPO_NAMESPACE=${VSH_GITHUB_REPO_NAMESPACE:="valet-sh"}
VSH_GITHUB_CLI_REPO_NAME=${VSH_GITHUB_CLI_REPO_NAME:="go-cli"}
VSH_DEBUG=${VSH_DEBUG:=0}

VSH_CLI_DIR="/usr/local/valet-sh/bin"
VSH_CLI_BINARY="valet.sh"
VSH_GITHUB_CLI_URL=${VSH_GITHUB_CLI_URL:="https://github.com/${VSH_GITHUB_REPO_NAMESPACE}/${VSH_GITHUB_CLI_REPO_NAME}"}

debug_log() {
  if [ $VSH_DEBUG -eq 1 ]; then
    printf 'DEBUG: %s \n' "${1}"
  fi
}

VSH_USER=${USER}
ARCH=$(uname -m)

# define stdout print function
out () {
    printf "\033[0;32m⠹ \033[;1m%s\033[0;0m | %s\n" "${VSH_NAME}" "${1}"
}

# trigger password prompt
sudo true

out "install"
echo ""
echo "full install log: ${VSH_INSTALL_LOG}"
echo ""
echo "" > ${VSH_INSTALL_LOG} 2>&1

# if linux
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    VSH_GROUP=${VSH_USER}

    VSH_GITHUB_LATEST_CLI_RELEASE_BINARY=${VSH_GITHUB_CLI_URL}/releases/latest/download/valet-linux-amd64
    debug_log "Detected OS: Linux amd64"
    debug_log "Download installer binary: ${VSH_GITHUB_LATEST_CLI_RELEASE_BINARY}"
fi

# if MacOS on Intel
if [[ "$OSTYPE" == "darwin"* ]] && [[ "$ARCH" == "x86_64"* ]]; then
    echo "Error: macOS on Intel (x86_64) is no longer supported." >&2
    exit 1
fi

# if MacOS on Apple Silicon
if [[ "$OSTYPE" == "darwin"* ]] && [[ "$ARCH" == "arm"* ]]; then
    VSH_GROUP="admin"

    VSH_GITHUB_LATEST_CLI_RELEASE_BINARY=${VSH_GITHUB_CLI_URL}/releases/latest/download/valet-darwin-arm64
    debug_log "Detected OS: MacOS arm64"
    debug_log "Download installer binary: ${VSH_GITHUB_LATEST_CLI_RELEASE_BINARY}"
fi

# create installer directory and ensure permissions are correct
debug_log "ensure ${VSH_CLI_DIR} exists"
sudo mkdir -p "${VSH_CLI_DIR}"

debug_log "check permissions for ${VSH_CLI_DIR}"
sudo chmod 775 "${VSH_CLI_DIR}"

debug_log "run chown ${VSH_USER}:${VSH_GROUP} ${VSH_CLI_DIR}"
sudo chown "${VSH_USER}":"${VSH_GROUP}" "${VSH_CLI_DIR}"

# download latest cli binary when none exists
if [ ! -f ${VSH_CLI_DIR}/${VSH_CLI_BINARY} ]; then
    debug_log "download binary ${VSH_GITHUB_LATEST_CLI_RELEASE_BINARY} to target ${VSH_CLI_DIR}/${VSH_CLI_BINARY}"

    if command -v curl &> /dev/null; then
        curl -fsSL -o ${VSH_CLI_DIR}/${VSH_CLI_BINARY} ${VSH_GITHUB_LATEST_CLI_RELEASE_BINARY} >> ${VSH_INSTALL_LOG} 2>&1
    elif command -v wget &> /dev/null; then
        wget -qO ${VSH_CLI_DIR}/${VSH_CLI_BINARY} ${VSH_GITHUB_LATEST_CLI_RELEASE_BINARY} >> ${VSH_INSTALL_LOG} 2>&1
    else
        out "ERROR: neither curl nor wget found. Please install curl or wget."
        exit 1
    fi

    debug_log "change permissions for ${VSH_CLI_DIR}/${VSH_CLI_BINARY}"
    chmod +x ${VSH_CLI_DIR}/${VSH_CLI_BINARY}
else
  debug_log "binary already exists: ${VSH_CLI_DIR}/${VSH_CLI_BINARY}"
fi

debug_log "create symlink for ${VSH_CLI_DIR}/${VSH_CLI_BINARY} to /usr/local/bin/${VSH_CLI_BINARY}"
sudo mkdir -p /usr/local/bin
sudo ln -sf "${VSH_CLI_DIR}/${VSH_CLI_BINARY}" /usr/local/bin/valet.sh

debug_log "start setup ${VSH_CLI_BINARY} setup"
command ${VSH_CLI_DIR}/${VSH_CLI_BINARY} setup

# output status
echo ""
echo ""
out "successfully installed ${VSH_NAME} version ${GIT_TAG}"
echo ""
echo -e "- Run '${VSH_NAME}' to get started"
echo -e "- Further documentation: ${VSH_URL}"
echo ""
