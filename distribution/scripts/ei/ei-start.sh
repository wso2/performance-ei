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
# Start WSO2 Enterprise Integrator
# ----------------------------------------------------------------------------

product=$1
heap_size=$2
if [[ -z $product ]]; then
    product=wso2ei-6.1.1
fi
if [[ -z $heap_size ]]; then
    heap_size="4"
fi

jvm_dir=""
for dir in /usr/lib/jvm/jdk1.8*; do
    [ -d "${dir}" ] && jvm_dir="${dir}" && break
done
export JAVA_HOME="${jvm_dir}"

carbon_bootstrap_class=org.wso2.carbon.bootstrap.Bootstrap
product_path=$HOME/$product

startup_script=$product_path/bin/wso2server.sh
if [[ $product == *"wso2ei"* ]]; then
    startup_script=$product_path/bin/integrator.sh
fi

if pgrep -f "$carbon_bootstrap_class" > /dev/null; then
    echo "Shutting down EI"
    $startup_script stop
fi

echo "Waiting for $product to stop"

while true
do
    if ! pgrep -f "$carbon_bootstrap_class" > /dev/null; then
        echo "$product stopped"
        break
    else
        sleep 10
    fi
done

log_files=($product_path/repository/logs/*)
if [ ${#log_files[@]} -gt 1 ]; then
    echo "Log files exists. Moving to /tmp"
    mv $product_path/repository/logs/* /tmp/;
fi

echo "Setting Heap to ${heap_size}GB"
export JVM_MEM_OPTS="-Xms${heap_size}G -Xmx${heap_size}G"

echo "Enabling GC Logs"
export JAVA_OPTS="-XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:$product_path/repository/logs/gc.log"

echo "Starting EI"
$startup_script start

echo "Waiting for $product to start"

while true 
do
    # Check Version service
    response_code="$(curl -sk -w "%{http_code}" -o /dev/null https://localhost:8243/services/Version)"
    if [ $response_code -eq 200 ]; then
        echo "$product started"
        break
    else
        sleep 10
    fi
done

# Wait for another 10 seconds to make sure that the server is ready to accept service requests.
sleep 10
