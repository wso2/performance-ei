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

script_dir=$(dirname "$0")
netty_host=$1
product=$2
if [[ -z $product ]]; then
    product=wso2ei-6.1.1
fi

validate() {
    if [[ -z  $1  ]]; then
        echo "Please provide arguments. Example: $0 netty_host product"
        exit 1
    fi
}

validate_command() {
    # Check whether given command exists
    # $1 is the command name
    # $2 is the package containing command
    if ! command -v $1 >/dev/null 2>&1; then
        echo "Please install $2 (sudo apt -y install $2)"
        exit 1
    fi
}

validate $netty_host

#Validate commands
validate_command unzip unzip

product_path="$HOME/$product"
product_name="Enterprise Integrator"

# Extract product
if [[ ! -f $product_path.zip ]]; then
    echo "Please download the $product_name to $HOME"
    exit 1
fi
if [[ ! -d $product_path ]]; then
    echo "Extracting $product_path.zip"
    unzip -q $product_path.zip -d $HOME
    echo "$product_name is extracted"
else
    echo "$product_name is already extracted"
    # exit 1
fi

capp_file=$script_dir/capp/ESBPerformanceTestArtifacts_1.0.0.car

if [ -f $capp_file ]; then
    echo "Deploying CAPP.."
    cp $capp_file $product_path/repository/deployment/server/carbonapps/
else
   echo "CAPP is not available."
   exit 1
fi

mkdir -p $product_path/repository/deployment/server/resources

store_jks_file=$script_dir/resources/store.jks

if [ -f $store_jks_file ]; then
    echo "Copying $store_jks_file file"
    mv $store_jks_file $product_path/repository/deployment/server/resources/
else
   echo "store.jks is not available."
fi

# Add Netty Host to /etc/hosts
sudo -s <<EOF
echo "$netty_host netty" >> /etc/hosts
EOF

echo "Completed..."
