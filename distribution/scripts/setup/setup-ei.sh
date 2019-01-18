#!/bin/bash
# Copyright 2018 WSO2 Inc. (http://wso2.org)
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
export netty_host=""
export ei_product=""
export user=""
export oracle_jdk_dist=""
# Default value for product extraction directory
export product_home="wso2ei"

function usageHelp() {
    echo "-n: The hostname of Netty Service."
    echo "-d: EI distribution."
    echo "-u: General user of the OS."
    echo "-j: Oracle JDK distribution. (If not provided, OpenJDK will be installed)"
}
export -f usageHelp

while getopts "hn:d:u:j:" opt; do
    case "${opt}" in
    n)
        netty_host=${OPTARG}
        ;;
    d)
        ei_product=${OPTARG}
        ;;
    u)
        user=${OPTARG}
        ;;
    j)
        oracle_jdk_dist=${OPTARG}
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

    if [[ ! -f $ei_product ]]; then
        echo "Product not provided. Please provide the EI product."
        exit 1
    fi

    if [[ -z $user ]]; then
        echo "Please provide the username of the general os user"
        exit 1
    fi
}
export -f validate

function setup() {
    install_dir=/home/$user
    if [[ -f $oracle_jdk_dist ]]; then
        $script_dir/../java/install-java.sh -f $oracle_jdk_dist
    fi

    pushd ${install_dir}

    #Remove Enterprise Integrator if it is already there
    if [[ -d wso2ei ]]; then
        sudo -u $user rm -rf wso2ei
    fi

    #Extract the downloaded zip
    echo "Extracting WSO2 Enterprise Integrator"
    sudo -u $user unzip -q -o $ei_product
    sudo -u $user mv -v wso2e* wso2ei
    echo "Enterprise Integrator is extracted"

    # Sample CAPP location
    capp_file=$script_dir/../ei/capp/EIPerformanceTestArtifacts-1.0.0.car

    if [ -f $capp_file ]; then
        echo "Deploying CAPP.."
        sudo -u $user cp -v $capp_file wso2ei/repository/deployment/server/carbonapps/
        echo "CAPP Deployed.."
    else
        echo "CAPP is not available."
        exit 1
    fi

    # Add Netty Host to /etc/hosts
    echo "$netty_host netty" >>/etc/hosts

    popd
    echo "Completed Enterprise Integrator setup..."
}
export -f setup

if [[ ! -f $oracle_jdk_dist ]]; then
    SETUP_COMMON_ARGS+="-p openjdk-8-jdk"
fi

$script_dir/../setup/setup-common.sh "${opts[@]}" "$@" -p curl -p jq -p unzip SETUP_COMMON_ARGS
