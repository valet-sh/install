#!/usr/bin/env bash

################################################################################
# valet.sh (un)installer
#
# Copyright: (C) 2018 TechDivision GmbH - All Rights Reserved
# Author: Johann Zelger <j.zelger@techdivision.com>
################################################################################

# exit immediately if a command exits with a non-zero status
set -e

# define variables
VSH_PREFIX="/usr/local"
VSH_GITHUB_REPO_NAMESPACE=${VSH_GITHUB_REPO_NAMESPACE:="valet-sh"}
VSH_GITHUB_REPO_NAME=${VSH_GITHUB_REPO_NAME:="valet-sh"}
VSH_GITHUB_REPO_URL=${VSH_GITHUB_REPO_URL:="https://github.com/${VSH_GITHUB_REPO_NAMESPACE}/${VSH_GITHUB_REPO_NAME}"}
VSH_INSTALL_DIR="${VSH_PREFIX}/${VSH_GITHUB_REPO_NAMESPACE}";
VSH_REPO_DIR="${VSH_INSTALL_DIR}/${VSH_GITHUB_REPO_NAME}"

# if git command is not available, install CLT
if [ ! -f /Library/Developer/CommandLineTools/usr/bin/git ]; then
    echo "Check Command Line Tools"
    # create macOS flag file, that CLT can be installed on demand
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    # parse CLT software name
    SOFTWARE_CLT_NAME=$(
        softwareupdate -l |
        grep -B 1 -E 'Command Line Tools' |
        awk -F'*' '/^ +\*/ {print $2}' |
        sed 's/^ *//' |
        grep -iE '[0-9|.]' |
        sort |
        tail -n1
    )
    echo "Installing (${SOFTWARE_CLT_NAME})"
    # install CLT
    softwareupdate -i "${SOFTWARE_CLT_NAME}" &> /dev/null
fi

# check if pip is available
if [ ! -x "$(command -v pip)" ]; then
    # retrigger sudo
    sudo true
    echo "Installing pip"
    # install pip
    sudo easy_install pip &> /dev/null
fi

# check if valet-sh is installed
if [ ! -d "${VSH_REPO_DIR}" ]; then
    echo "Installing valet-sh"
    # retrigger sudo
    sudo true
    # cleanup old installations (< version 1.0.0-alpha10)
    rm -rf "${HOME}/.valet.sh"
    rm -rf "${HOME}/.valet-sh"
    # create install dir if it does not exist
    if [ ! -d "${VSH_INSTALL_DIR}" ]; then
        sudo mkdir "${VSH_INSTALL_DIR}"
    fi
    # set correct permissions
    sudo chmod 775 "${VSH_INSTALL_DIR}"
    sudo chown "${USER}":admin "${VSH_INSTALL_DIR}"
    # install by cloning git repo to install dir
    git clone --quiet "${VSH_GITHUB_REPO_URL}" "${VSH_REPO_DIR}"
    # fetch all tags from application git repo
    git --git-dir="${VSH_REPO_DIR}/.git" --work-tree="${VSH_REPO_DIR}" fetch --tags --quiet
    # get available git tags sorted by refname
    GIT_TAGS=$(git --git-dir="${VSH_REPO_DIR}/.git" --work-tree="${VSH_REPO_DIR}" tag --sort "-v:refname" )
    # get latest semver conform git version tag
    for GIT_TAG in ${GIT_TAGS}; do
        # validate tag to be semver compliant
        if [[ "${GIT_TAG}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$ ]]; then
            # checkout latest semver compliant git tag
            git --git-dir="${VSH_REPO_DIR}/.git" --work-tree="${VSH_REPO_DIR}" checkout --force --quiet "${GIT_TAG}"
            break
        fi
    done
    echo "Installing dependencies"
    # install python dependencies via pip
    sudo pip install -Iq -r requirements.txt &> /dev/null
    # create or override old symlink to prefix bin directory
    sudo ln -sf "${VSH_REPO_DIR}/valet.sh" "${VSH_PREFIX}/bin/"
    # output log
    echo "Successfully installed version ${GIT_TAG}"
else
    echo "Already installed"
fi
