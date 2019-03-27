#!/bin/bash -e
# Copyright 2019 WSO2 Inc. (http://wso2.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ----------------------------------------------------------------------------
# Setup WSO2 Enterprise Integrator
# ----------------------------------------------------------------------------
# Make sure the script is running as root.
if [ "$UID" -ne "0" ]; then
    echo "You must be root to run $0. Try following"
    echo "sudo $0"
    exit 9
fi

export script_dir=$(dirname "$0")
export oracle_jdk_dist=""
export micro_ei_docker_image=""
export user=""
export netty_host=""

function usageHelp() {
    echo "-n: The hostname of Netty Service."
    echo "-d: EI distribution."
    echo "-u: General user of the OS."
    echo "-j: Oracle JDK distribution. (If not provided, OpenJDK will be installed)"
    echo "-i: Docker image of the micro integrator."
}
export -f usageHelp

while getopts "hn:u:i:j" opt; do
    case "${opt}" in
    n)
        netty_host=${OPTARG}
        ;;
    u)
        user=${OPTARG}
        ;;
    j)
        oracle_jdk_dist=${OPTARG}
        ;;
    i)
        micro_ei_docker_image=${OPTARG}
        ;;
    h)
        usageHelp
        exit 0
        ;;
    *)
        opts+=("-${opt}")
        [[ -n "$OPTARG" ]] && opts+=("$OPTARG")
        ;;
    esac
done
shift "$((OPTIND - 1))"

# Validating input parameters
validate() {
    if [[ -z $netty_host ]]; then
        echo "Please provide netty host."
        exit 1
    fi

    if [[ ! -f $micro_ei_docker_image ]]; then
        echo "Docker image for micro integrator not provided. Please provide the Docker image path."
        exit 1
    fi

    if [[ -z $user ]]; then
        echo "Please provide the username of the general os user"
        exit 1
    fi
}
export -f validate

function createNettyIPFile() {
    current_dir=$PWD
    nettyIPfile=$PWD/nettyIP.txt
    if [ -f "$nettyIPfile" ]
    then
        rm $nettyIPfile
        touch $nettyIPfile
        echo "$netty_host" > "$nettyIPfile"
    else
        touch $nettyIPfile
        echo "$netty_host" > "$nettyIPfile"
    fi
    cd $current_dir
}

createNettyIPFile

function setup() {
    if command -v docker >/dev/null 2>&1; then
#       sudo docker pull docker.wso2.com/wso2ei-micro-integrator:6.4.0
        sudo docker load -i $micro_ei_docker_image
    fi
}
export -f setup

if [[ ! -f $oracle_jdk_dist ]]; then
    SETUP_COMMON_ARGS+="-p openjdk-8-jdk"
fi

$script_dir/../setup/setup-common.sh "${opts[@]}" "$@" -p curl -p jq -p unzip SETUP_COMMON_ARGS