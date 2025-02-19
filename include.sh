#!/usr/bin/env bash

################################################################################
# valet.sh variables and functions for external include usage.
#
# Copyright: (C) 2021 TechDivision GmbH - All Rights Reserved
# Author: Johann Zelger <j.zelger@techdivision.com>
################################################################################

VSH_INSTALL_LOG="/tmp/valet-sh-install.log"
# semver validator regex
SEMVER_REGEX='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'

##############################################################################
# install or upgrade application repository
##############################################################################
function install_upgrade() {
    # init variables
    REPO_URL="${1}"
    REPO_DIR="${2}"
    TAG_FILTER="${3}"
    # clone if repo dir is not set yet
    if [[ ! -d "${REPO_DIR}" ]]; then
        git clone --quiet "${REPO_URL}" "${REPO_DIR}" >> ${VSH_INSTALL_LOG} 2>&1
    fi
    # fetch all tags from application git repo
    git --git-dir="${REPO_DIR}/.git" --work-tree="${REPO_DIR}" fetch --tags --quiet
    # get available git tags sorted by refname
    GIT_TAGS=$(git --git-dir="${REPO_DIR}/.git" --work-tree="${REPO_DIR}" tag --sort "-v:refname" | grep "${TAG_FILTER}")
    # get latest semver conform git version tag
    for GIT_TAG in ${GIT_TAGS}; do
        # validate tag to be semver compliant
        if [[ "${GIT_TAG}" =~ ${SEMVER_REGEX} ]]; then
            # checkout latest semver compliant git tag
            git --git-dir="${REPO_DIR}/.git" --work-tree="${REPO_DIR}" checkout --force --quiet "${GIT_TAG}"
            break
        fi
    done

    # return used git tag
    echo "${GIT_TAG}"
}

##############################################################################
# migration scripts
##############################################################################
function install_migration() {
    # deinstall user systemwide installation of valet-sh-cli
    pip3 uninstall -y valet-sh-cli &> /dev/null || true
}

##############################################################################
# install dependencies
##############################################################################
function install_dependencies() {
    VENV_DIR="${1}"
    REPO_DIR="${2}"
    PIP_INSTALL_OPTS=""
    VENV_CREATE_OPTS=""

    # call possible migration
    install_migration

    # check if there is linux and modify command opts
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        PIP_INSTALL_OPTS="-I"
        VENV_CREATE_OPTS="--system-site-packages"
        PYTHON3_BIN="/usr/bin/python3"
    fi

    # if MacOS
    if [[ "$OSTYPE" == "darwin"* ]] && [[ "$ARCH" == "x86"* ]]; then
        PYTHON3_BIN="/usr/local/opt/python@3.10/bin/python3.10"
    fi

    # if MacOS on M1
    if [[ "$OSTYPE" == "darwin"* ]] && [[ "$ARCH" == "arm"* ]]; then
        PYTHON3_BIN="/opt/homebrew/opt/python@3.10/bin/python3.10"
    fi
    
    # clone if repo dir is not set yet
    if [[ ! -d "${VENV_DIR}" ]]; then
        # (re)create venv if it does not exist
        ${PYTHON3_BIN} -m venv ${VENV_CREATE_OPTS} "${VENV_DIR}" >> ${VSH_INSTALL_LOG} 2>&1
    fi
    # activate valet.sh venv
    # shellcheck source=/dev/null
    source "${VENV_DIR}/bin/activate"
    # install python dependencies via pip3
    pip3 install ${PIP_INSTALL_OPTS} --upgrade setuptools==60.8.2 wheel==0.37.1 >> ${VSH_INSTALL_LOG} 2>&1
    echo " - install ansible"
    pip3 install ${PIP_INSTALL_OPTS} -r "${REPO_DIR}/requirements.txt" >> ${VSH_INSTALL_LOG} 2>&1
    # check if there is a requirements.yml in repo dir
    if [ -f "${REPO_DIR}/requirements.yml" ]; then
        # install collections based on requirements.yml file in repo dir
        echo " - install python dependencies"
        ANSIBLE_COLLECTIONS_PATHS="${REPO_DIR}/collections" ansible-galaxy collection install -r "${REPO_DIR}/requirements.yml" -p "${REPO_DIR}/collections" >> ${VSH_INSTALL_LOG} 2>&1
    fi
    # deactivate valet.sh venv
    deactivate
}

##############################################################################
# (re)sets symlink to cli command
##############################################################################
function install_link() {
    VENV_DIR="${1}"

    if [[ ! -d "/usr/local/bin" ]]; then
      sudo mkdir /usr/local/bin
      sudo chown -R $USER /usr/local/bin
    fi

    # (re)set system-wide symlink to be in path
    sudo ln -sf "${VENV_DIR}/bin/valet.sh" "/usr/local/bin/valet.sh"
}

