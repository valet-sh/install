#!/usr/bin/env bash

################################################################################
# valet.sh installer
#
# Copyright: (C) 2025 TechDivision GmbH - All Rights Reserved
# Author: Philipp Dittert <p.dittert@techdivision.com>
################################################################################

# exit immediately if a command exits with a non-zero status
set -e

# define variables
VSH_NAME="valet.sh"
VSH_URL="https://valet.sh"
VSH_PREFIX="/usr/local"
VSH_INSTALLER_SUFFIX="installer"
VSH_INSTALL_LOG="/tmp/valet-sh-install.log"
VSH_GITHUB_REPO_NAMESPACE=${VSH_GITHUB_REPO_NAMESPACE:="valet-sh"}
VSH_GITHUB_INSTALLER_REPO_NAME=${VSH_GITHUB_INSTALLER_REPO_NAME:="installer"}
VSH_DEBUG=${VSH_DEBUG:=0}


VSH_INSTALLER_DIR=${VSH_PREFIX}/${VSH_GITHUB_REPO_NAMESPACE}/${VSH_INSTALLER_SUFFIX}
VSH_INSTALLER_BINARY=valet-sh-installer
VSH_GITHUB_INSTALLER_URL=${VSH_GITHUB_INSTALLER_URL:="https://github.com/${VSH_GITHUB_REPO_NAMESPACE}/${VSH_GITHUB_INSTALLER_REPO_NAME}"}

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

    VSH_GITHUB_LATEST_INSTALLER_RELEASE_BINARY=${VSH_GITHUB_INSTALLER_URL}/releases/latest/download/valet-sh-installer_linux_amd64
    debug_log "Detected OS: Linux amd64"
    debug_log "Download installer binary: ${VSH_GITHUB_LATEST_INSTALLER_RELEASE_BINARY}"
fi

# if MacOS on Intel
if [[ "$OSTYPE" == "darwin"* ]] && [[ "$ARCH" == "x86_64"* ]]; then
    VSH_GROUP="admin"

    VSH_GITHUB_LATEST_INSTALLER_RELEASE_BINARY=${VSH_GITHUB_INSTALLER_URL}/releases/latest/download/valet-sh-installer_darwin_amd64
    debug_log "Detected OS: MacOS amd64"
    debug_log "Download installer binary: ${VSH_GITHUB_LATEST_INSTALLER_RELEASE_BINARY}"
fi

# if MacOS on Apple Silicon
if [[ "$OSTYPE" == "darwin"* ]] && [[ "$ARCH" == "arm"* ]]; then
    VSH_GROUP="admin"

    VSH_GITHUB_LATEST_INSTALLER_RELEASE_BINARY=${VSH_GITHUB_INSTALLER_URL}/releases/latest/download/valet-sh-installer_darwin_arm64
    debug_log "Detected OS: MacOS arm64"
    debug_log "Download installer binary: ${VSH_GITHUB_LATEST_INSTALLER_RELEASE_BINARY}"
fi

# create installer directory and ensure permissions are correct
debug_log "ensure ${VSH_INSTALLER_DIR} exists"
sudo mkdir -p "${VSH_INSTALLER_DIR}"

debug_log "check permissions for ${VSH_INSTALLER_DIR}"
sudo chmod 775 "${VSH_INSTALLER_DIR}"

debug_log "run chown ${VSH_USER}:${VSH_GROUP} ${VSH_INSTALLER_DIR}"
sudo chown "${VSH_USER}":"${VSH_GROUP}" "${VSH_INSTALLER_DIR}"

# download latest installer binary when none exists
if [ ! -f ${VSH_INSTALLER_DIR}/${VSH_INSTALLER_BINARY} ]; then
    debug_log "download binary ${VSH_GITHUB_LATEST_INSTALLER_RELEASE_BINARY} to target ${VSH_INSTALLER_DIR}/${VSH_INSTALLER_BINARY}"
    /bin/bash -c "$(curl -fsSL -o ${VSH_INSTALLER_DIR}/${VSH_INSTALLER_BINARY} ${VSH_GITHUB_LATEST_INSTALLER_RELEASE_BINARY})" >> ${VSH_INSTALL_LOG} 2>&1

    debug_log "change permissions for ${VSH_INSTALLER_DIR}/${VSH_INSTALLER_BINARY}"
    chmod +x ${VSH_INSTALLER_DIR}/${VSH_INSTALLER_BINARY}
else
  debug_log "binary already exists: ${VSH_INSTALLER_DIR}/${VSH_INSTALLER_BINARY}"
fi

debug_log "start setup ${VSH_INSTALLER_BINARY} setup"
command ${VSH_INSTALLER_DIR}/${VSH_INSTALLER_BINARY} setup

# output status
echo ""
echo ""
out "successfully installed ${VSH_NAME} version ${GIT_TAG}"
echo ""
echo -e "- Run '${VSH_NAME}' to get started"
echo -e "- Further documentation: ${VSH_URL}"
echo ""
