#!/usr/bin/env bash

################################################################################
# valet.sh (un)installer
#
# Copyright: (C) 2022 TechDivision GmbH - All Rights Reserved
# Author: Johann Zelger <j.zelger@techdivision.com>
################################################################################

# exit immediately if a command exits with a non-zero status
set -e

# define variables
VSH_NAME="valet.sh"
VSH_URL="https://valet.sh"
VSH_PREFIX="/usr/local"
HOMEBREW_PREFIX="/usr/local"
VSH_INSTALL_LOG="/tmp/valet-sh-install.log"
VSH_GITHUB_REPO_NAMESPACE=${VSH_GITHUB_REPO_NAMESPACE:="valet-sh"}
VSH_GITHUB_REPO_NAME=${VSH_GITHUB_REPO_NAME:="valet-sh"}
VSH_GITHUB_REPO_URL=${VSH_GITHUB_REPO_URL:="https://github.com/${VSH_GITHUB_REPO_NAMESPACE}/${VSH_GITHUB_REPO_NAME}"}
VSH_INCLUDE_URL=${VSH_INCLUDE_URL:="https://raw.githubusercontent.com/${VSH_GITHUB_REPO_NAMESPACE}/install/develop/include.sh"}
VSH_INSTALL_DIR="${VSH_PREFIX}/${VSH_GITHUB_REPO_NAMESPACE}"
VSH_REPO_DIR="${VSH_INSTALL_DIR}/${VSH_GITHUB_REPO_NAME}"
VSH_VENV_DIR="${VSH_INSTALL_DIR}/venv"
VSH_USER=${USER}
ARCH=$(uname -m)

# include external vars and functions
# shellcheck disable=SC1091
source /dev/stdin <<< "$( curl -sS ${VSH_INCLUDE_URL} )"

# define stdout print function
out () {
    printf "\033[0;32m⠹ \033[;1m%s\033[0;0m | %s\n" "${VSH_NAME}" "${1}"
}

out "install"
echo ""
echo "full install log: ${VSH_INSTALL_LOG}"
echo ""

# trigger password promt
sudo true

# if linux
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    # update apt package index files
    sudo apt update && sudo apt -y install git python3 python3-venv
    VSH_GROUP=${VSH_USER}
fi

# if MacOS on M1
if [[ "$OSTYPE" == "darwin"* ]] && [[ "$ARCH" == "arm"* ]]; then
  HOMEBREW_PREFIX="/opt/homebrew"
fi

# if MacOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # check if brew is installed
    if ! command -v ${HOMEBREW_PREFIX}/bin/brew &> /dev/null
        then
            echo "brew could not be found. Installing..."
            yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > ${VSH_INSTALL_LOG} 2>&1
            export CPPFLAGS=-I${HOMEBREW_PREFIX}/opt/openssl/include
            export LDFLAGS=-L${HOMEBREW_PREFIX}/opt/openssl/lib
        fi

    echo "installing required brew packages"
    ${HOMEBREW_PREFIX}/bin/brew install openssl rust python@3.10 > ${VSH_INSTALL_LOG} 2>&1

    # init brew services by calling it
    ${HOMEBREW_PREFIX}/bin/brew services list > ${VSH_INSTALL_LOG} 2>&1
    VSH_GROUP="admin"
fi

# create install base dir if it does not exist
if [ ! -d "${VSH_INSTALL_DIR}" ]; then
    sudo mkdir "${VSH_INSTALL_DIR}"
fi
# reset correct permissions
sudo chmod 775 "${VSH_INSTALL_DIR}"
sudo chown "${VSH_USER}":"${VSH_GROUP}" "${VSH_INSTALL_DIR}"

# mv repo dir to tmp folder if exists deleting it after installation
mv "${VSH_REPO_DIR}" "/tmp/${VSH_GITHUB_REPO_NAME}" &> ${VSH_INSTALL_LOG} || true
# install application
install_upgrade "${VSH_GITHUB_REPO_URL}" "${VSH_REPO_DIR}"

# mv venv to tmp folder if exists deleting it after installation
mv ${VSH_VENV_DIR} "/tmp/${VSH_GITHUB_REPO_NAMESPACE}-venv" &> ${VSH_INSTALL_LOG} || true
# install dependencies in venv
install_dependencies "${VSH_VENV_DIR}" "${VSH_REPO_DIR}"

# (re)set system-wide symlink to be in path
install_link "${VSH_VENV_DIR}"

# cleanup
rm -rf "/tmp/${VSH_GITHUB_REPO_NAMESPACE}-venv" &> ${VSH_INSTALL_LOG} || true
rm -rf "/tmp/${VSH_GITHUB_REPO_NAME}" &> ${VSH_INSTALL_LOG} || true

# output status
echo ""
echo ""
out "successfully installed ${VSH_NAME} version ${GIT_TAG}"
echo ""
echo -e "- Run '${VSH_NAME}' to get started"
echo -e "- Further documentation: ${VSH_URL}"
echo ""
