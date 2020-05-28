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
export micro_ei_docker_image=""
export user=""
export netty_host=""

function usageHelp() {
    echo "-n: The hostname of Netty Service."
    echo "-u: General user of the OS."
    # echo "-i: Docker image of the micro integrator."
}
export -f usageHelp

while getopts "n:u:h" opt; do
    case "${opt}" in
    n)
        netty_host=${OPTARG}
        ;;
    u)
        user=${OPTARG}
        ;;
    # i)
    #     micro_ei_docker_image=${OPTARG}
    #     ;;
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

    # if [[ ! -f $micro_ei_docker_image ]]; then
    #     echo "Docker image for micro integrator not provided. Please provide the Docker image path."
    #     exit 1
    # fi

    if [[ -z $user ]]; then
        echo "Please provide the username of the general os user"
        exit 1
    fi
}
export -f validate

function setup() {
    $script_dir/../docker/install-docker.sh -u $user
    # docker load -i $micro_ei_docker_image
    # Add Netty Host to /etc/hosts
    echo "$netty_host netty" >>/etc/hosts
}
export -f setup

$script_dir/../setup/setup-common.sh "${opts[@]}" "$@" -p curl -p jq -p unzip
