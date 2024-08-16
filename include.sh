#!/usr/bin/env bash

################################################################################
# valet.sh variables and functions for external include usage.
#
# Copyright: (C) 2021 TechDivision GmbH - All Rights Reserved
# Author: Johann Zelger <j.zelger@techdivision.com>
# Author: Philipp Dittert <p.dittert@techdivision.com>
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
    install_upgrade_runtime "${1}" "${2}"
}

##############################################################################
# (re)sets symlink to cli command
##############################################################################
function install_link() {
    VENV_DIR="${1}"

    if [[ ! -d "/usr/local/bin" ]]; then
      sudo mkdir /usr/local/bin
      sudo chown -R "$USER" /usr/local/bin
    fi

    # (re)set system-wide symlink to be in path
    sudo ln -sf "${VENV_DIR}/bin/valet.sh" "/usr/local/bin/valet.sh"
}

##############################################################################
# install or upgrade runtime package
##############################################################################
function install_upgrade_runtime() {
    VENV_DIR="${1}"
    REPO_DIR="${2}"

    echo "debug-1"

    # call possible migration
    install_migration

    echo "debug-12"

    # when valet-sh project contains no .runtime_version file to nothing
    if [ ! -f "${REPO_DIR}/.runtime_version" ]
    then
      return
    fi

    echo "debug-13"

    # when current installed venv has no .version file, replace with runtime package
    if [ ! -f "${VENV_DIR}/.version" ]
    then
      do_runtime_upgrade "${VENV_DIR}" "${REPO_DIR}"
      return
    fi

    echo "debug0"

    # when desired .runtime_version differs from installed .version, replace runtime
    diff -q "${REPO_DIR}/.runtime_version" "${VENV_DIR}/.version" > /dev/null 2>&1

    echo "debug1"

    DIFF=$?

    echo "debug2"

    if [ "$DIFF" -ne "0" ]
    then
      echo "debug3"
      do_runtime_upgrade "${VENV_DIR}" "${REPO_DIR}"
      return
    fi
}

##############################################################################
# actual upgrade runtime package
##############################################################################
function do_runtime_upgrade() {
    VENV_DIR="${1}"
    REPO_DIR="${2}"
    VSH_BASE_DIR="$(dirname "$VENV_DIR")"

    TARGET_RUNTIME_VERSION="$(cat "${REPO_DIR}"/.runtime_version)"

    # if Linux/Ubuntu
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        . /etc/os-release

        RUNTIME_PACKAGE="${ID}-${VERSION_CODENAME}-amd64"
    fi

    # if MacOS
    if [[ "$OSTYPE" == "darwin"* ]] && [[ "$ARCH" == "x86"* ]]; then
        RUNTIME_PACKAGE="macos-amd64"
    fi

    # if MacOS on M1
    if [[ "$OSTYPE" == "darwin"* ]] && [[ "$ARCH" == "arm"* ]]; then
        RUNTIME_PACKAGE="macos-arm64"
    fi

    TARGET_RUNTIME_FILENAME=${RUNTIME_PACKAGE}.tar.gz

    TARGET_RUNTIME_DOWNLOAD_URL=https://github.com/valet-sh/runtime/releases/download/${TARGET_RUNTIME_VERSION}/${TARGET_RUNTIME_FILENAME}

    echo "Check for runtime release ${TARGET_RUNTIME_VERSION}"

    TARGET_RUNTIME_RELEASE_CHECK=$(curl -I -L -s -o /dev/null -w "%{http_code}" "${TARGET_RUNTIME_DOWNLOAD_URL}")

    if [[ "$TARGET_RUNTIME_RELEASE_CHECK" != "200" ]]; then
      echo "Runtime release ${TARGET_RUNTIME_VERSION} not available!"
      exit 1
    fi

    echo "Downloading runtime release ${TARGET_RUNTIME_VERSION}"

    curl -L -s -o "${VSH_BASE_DIR}"/"${TARGET_RUNTIME_FILENAME}" "${TARGET_RUNTIME_DOWNLOAD_URL}"

    if [ $? -ne 0 ]; then
        echo "Runtime download failed. Please check our internet connection and try it again..."
        exit 1
    fi

    if [ -d "$VENV_DIR" ]; then
      mv "${VENV_DIR}" "${VENV_DIR}-tmp"
    fi

    echo "Installing runtime..."

    tar -xzf "${VSH_BASE_DIR}"/"${TARGET_RUNTIME_FILENAME}" -C "${VSH_BASE_DIR}"

    if [ $? -ne 0 ]; then
        echo "Runtime installation failed..."
        exit 1
    fi

    echo "cleaning up..."

    if [ -d "${VENV_DIR}-tmp" ]; then
      rm -r "${VENV_DIR}-tmp"
    fi

    rm "${VSH_BASE_DIR}"/"${TARGET_RUNTIME_FILENAME}"


}
