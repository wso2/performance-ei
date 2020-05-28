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
# Start WSO2 Enterprise Micro Integrator
# ----------------------------------------------------------------------------
script_dir=$(dirname "$0")
default_heap_size="1G"
heap_size="$default_heap_size"
cpus=""
memory=""
wso2_ei_version=""
default_server_type="microei"
server_type="$default_server_type"

function usage() {
    echo ""
    echo "Usage: "
    echo "$0 -c <cpus> -r <memory> -v <wso2_ei_version> [-m <heap_size>] [-a <server_type>] [-h]"
    echo "-c: Number of CPU resources to be used by the container."
    echo "-r: The maximum amount of memory the container can use."
    echo "-v: WSO2 Micro Integrator Integrator version."
    echo "-m: The heap memory size of Micro Integrator. Default: $default_heap_size."
    echo "-h: Display this help and exit."
    echo ""
}

while getopts "c:r:v:m:h" opt; do
    case "${opt}" in
    c)
        cpus=${OPTARG}
        ;;
    r)
        memory=${OPTARG}
        ;;
    v)
        wso2_ei_version=${OPTARG}
        ;;
    m)
        heap_size=${OPTARG}
        ;;
    h)
        usage
        exit 0
        ;;
    \?)
        usage
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"

if [[ -z $cpus ]]; then
    echo "Please provide the number of CPU resources to be used by the container."
    exit 1
fi

if [[ -z $memory ]]; then
    echo "Please provide the maximum amount of memory the container can use."
    exit 1
fi

if [[ -z $wso2_ei_version ]]; then
    echo "Please provide WSO2 Enterprise Integrator version."
    exit 1
fi

if [[ -z $heap_size ]]; then
    echo "Please provide the heap size for Micro Integrator."
    exit 1
fi

netty_host=$(getent hosts netty | awk '{ print $1 }')

echo "Setting Heap to ${heap_size}"
JVM_MEM_OPTS="JVM_MEM_OPTS=-Xms${heap_size} -Xmx${heap_size}"

echo "Enabling GC Logs"
JAVA_OPTS="JAVA_OPTS=-XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/home/wso2carbon/wso2ei-${wso2_ei_version}/wso2/micro-integrator/repository/logs/gc.log"

if [[ ! -d ${HOME}/logs ]]; then
    mkdir -p ${HOME}/logs
    chmod -R 777 ${HOME}/logs
fi

echo -n >${HOME}/logs/wso2carbon.log
echo -n >${HOME}/logs/gc.log
chmod o+w ${HOME}/logs/wso2carbon.log
chmod o+w ${HOME}/logs/gc.log

# Sample CAPP location
capp_dir=$script_dir/capp/

set -x
docker run --name=microei -d -p 8290:8290 -p 9201:9201 -p 8253:8253 --add-host=netty:$netty_host --cpus=${cpus} --memory=${memory} \
        --volume $(realpath $capp_dir):/home/wso2carbon/wso2mi-${wso2_ei_version}/repository/deployment/server/carbonapps \
        --volume ${HOME}/logs/wso2carbon.log:/home/wso2carbon/wso2mi-${wso2_ei_version}/repository/logs/wso2carbon.log \
        --volume ${HOME}/logs/gc.log:/home/wso2carbon/wso2mi-${wso2_ei_version}/repository/logs/gc.log \
        -e "${JVM_MEM_OPTS}" -e "${JAVA_OPTS}" wso2/wso2mi:${wso2_ei_version}

echo "Waiting for MI to start."

exit_status=100
n=0
until [ $n -ge 60 ]; do
   response_code=$(curl -s -w '%{http_code}' -o /dev/null http://localhost:9201/healthz || echo "")
   if [ $response_code -eq 200 ]; then
       echo "MI started"
       exit_status=0
       break
   fi
   sleep 5
   n=$(($n + 1))
done

# Wait for 10 seconds to make sure that the server is ready to accept API requests.
sleep 10
exit $exit_status
