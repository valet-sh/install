#!/usr/bin/env bash

################################################################################
# valet.sh (un)installer
#
# Copyright: (C) 2021 TechDivision GmbH - All Rights Reserved
# Author: Johann Zelger <j.zelger@techdivision.com>
################################################################################

# exit immediately if a command exits with a non-zero status
set -e

# define variables
VSH_NAME="valet.sh"
VSH_URL="https://valet.sh"
VSH_PREFIX="/usr/local"
VSH_GITHUB_REPO_NAMESPACE=${VSH_GITHUB_REPO_NAMESPACE:="valet-sh"}
VSH_GITHUB_REPO_NAME=${VSH_GITHUB_REPO_NAME:="valet-sh"}
VSH_GITHUB_REPO_URL=${VSH_GITHUB_REPO_URL:="https://github.com/${VSH_GITHUB_REPO_NAMESPACE}/${VSH_GITHUB_REPO_NAME}"}
VSH_INCLUDE_URL=${VSH_INCLUDE_URL:="https://raw.githubusercontent.com/${VSH_GITHUB_REPO_NAMESPACE}/install/master/include.sh"}
VSH_INSTALL_DIR="${VSH_PREFIX}/${VSH_GITHUB_REPO_NAMESPACE}"
VSH_REPO_DIR="${VSH_INSTALL_DIR}/${VSH_GITHUB_REPO_NAME}"
VSH_VENV_DIR="${VSH_INSTALL_DIR}/venv"
VSH_USER=${USER}

# include external vars and functions
# shellcheck disable=SC1091
source /dev/stdin <<< "$( curl -sS ${VSH_INCLUDE_URL} )"

# define stdout print function
out () {
    printf "\033[0;32m⠹ \033[;1m%s\033[0;0m | %s\n" "${VSH_NAME}" "${1}"
}

out "install"

# trigger password promt
sudo true

# if linux
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    # update apt package index files
    sudo apt update && sudo apt -y install git python3 python3-venv
    VSH_GROUP=${VSH_USER}
fi

# if MacOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # check if brew is installed
    if ! command -v brew &> /dev/null
        then
            out "brew could not be found. Installing..."
            yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            brew install openssl rust python3
            export CPPFLAGS=-I/usr/local/opt/openssl/include
            export LDFLAGS=-L/usr/local/opt/openssl/lib
        fi
    # init brew services by calling it
    brew services list &> /dev/null
    
    # check if python3 is installed
    if ! command -v python3 &> /dev/null
        then
            out "python3 could not be found. Installing..."
            brew install python3
        fi
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
mv "${VSH_REPO_DIR}" "/tmp/${VSH_GITHUB_REPO_NAME}" &> /dev/null || true
# install application
install_upgrade "${VSH_GITHUB_REPO_URL}" "${VSH_REPO_DIR}"

# mv venv to tmp folder if exists deleting it after installation
mv ${VSH_VENV_DIR} "/tmp/${VSH_GITHUB_REPO_NAMESPACE}-venv" &> /dev/null || true
# install dependencies in venv
install_dependencies "${VSH_VENV_DIR}" "${VSH_REPO_DIR}"

# (re)set system-wide symlink to be in path
install_link "${VSH_VENV_DIR}"

# cleanup
rm -rf "/tmp/${VSH_GITHUB_REPO_NAMESPACE}-venv" &> /dev/null || true
rm -rf "/tmp/${VSH_GITHUB_REPO_NAME}" &> /dev/null || true

# output status
echo ""
echo ""
out "successfully installed ${VSH_NAME} version ${GIT_TAG}"
echo ""
echo -e "- Run '${VSH_NAME}' to get started"
echo -e "- Further documentation: ${VSH_URL}"
echo ""
