#!/usr/bin/env bash

################################################################################
# valet.sh (un)installer
#
# Copyright: (C) 2018 TechDivision GmbH - All Rights Reserved
# Author: Johann Zelger <j.zelger@techdivision.com>
################################################################################

# if git command is not available, install CLT
if [ ! -f /Library/Developer/CommandLineTools/usr/bin/git ]; then
    echo "Installing CommandLineTools \e[32m$command\e[39m"    
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
    # install CLT
    softwareupdate -i "${SOFTWARE_CLT_NAME}"
fi

# check if ansible-playbook is available
if [ ! -x "$(command -v ansible-playbook)" ]; then
    # test and trigger sudo for MacOS timeout (sudo)
    sudo true
    echo "Installing Ansible"
    # if ansible is not available, install pip and ansible
    sudo easy_install pip &> /dev/null
    sudo pip install -Iq ansible &> /dev/null
fi