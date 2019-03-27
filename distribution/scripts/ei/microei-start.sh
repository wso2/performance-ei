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
default_heap_size="4G"
heap_size="$default_heap_size"
cpu_num="0.5"
version="6.4.0"
export script_dir=$(dirname "$0")

function usageHelp() {
    echo "-m: Heap memory size. Default value: $default_heap_size"
    echo "-c: Number of cpus allocated. Default value: $cpu_num"
    echo "-t: EI profile(EI/MicroEI)."
}
export -f usageHelp

while getopts "m:c:h" opts; do
    case $opts in
    m)
        heap_size=${OPTARG}
        ;;
    c)
        cpu_num=${OPTARG}
        ;;
    v)
        version=${OPTARG}
        ;;
    h)
        usageHelp
        exit 0
        ;;
    *)
        usageHelp
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"

function validate() {
    if [[ -z $heap_size ]]; then
        echo "Please provide the heap size for the EI program."
        exit 1
    fi
}
validate

jvm_dir=""
for dir in /usr/lib/jvm/jdk1.8*; do
    [ -d "${dir}" ] && jvm_dir="${dir}" && break
done
export JAVA_HOME="${jvm_dir}"

echo "Setting Heap to ${heap_size}"
JVM_MEM_OPTS="JVM_MEM_OPTS=-Xms${heap_size} -Xmx${heap_size}"

echo "Enabling GC Logs"
JAVA_OPTS="JAVA_OPTS=-XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/home/wso2carbon/wso2ei-${version}/wso2/micro-integrator/repository/logs/gc.log"

if [[ ! -d ${HOME}/logs ]]; then
    mkdir ${HOME}/logs
    echo >${HOME}/logs/wso2carbon.log
    echo >${HOME}/logs/gc.log
    chmod -R 777 ${HOME}/logs
else
    echo -n > ${HOME}/logs/wso2carbon.log
    echo -n > ${HOME}/logs/gc.log
fi

carbon_bootstrap_class=org.wso2.carbon.bootstrap.Bootstrap
# Sample CAPP location
capp_dir=$script_dir/../ei/capp/
echo "Starting the docker container"
sudo docker run -d -p 8280:8280 -p 8243:8243 --network="host" --cpus=${cpu_num} \
--volume $(readlink -f $capp_dir):/home/wso2carbon/wso2ei-${version}/wso2/micro-integrator/repository/deployment/server/carbonapps \
--volume ${HOME}/carbon.xml:/home/wso2carbon/wso2ei-${version}/wso2/micro-integrator/conf/carbon.xml \
--volume ${HOME}/logs/wso2carbon.log:/home/wso2carbon/wso2ei-${version}/wso2/micro-integrator/repository/logs/wso2carbon.log \
--volume ${HOME}/logs/gc.log:/home/wso2carbon/wso2ei-${version}/wso2/micro-integrator/repository/logs/gc.log \
-e "${JVM_MEM_OPTS}" -e "${JAVA_OPTS}" wso2ei-micro-integrator:${version}

echo "Waiting for EI to start"
sleep 40

exit_status=100
n=0
until [ $n -ge 60 ]; do
    response_code=$(curl -sk -w "%{http_code}" -o /dev/null http://localhost:8280/echo)
    if [ $response_code -eq 200 ]; then
        echo "EI started"
        exit_status=0
        break
    else
        sleep 10
    fi
    n=$(($n + 1))
done

# Wait for 10 seconds to make sure that the server is ready to accept API requests.
sleep 10
exit $exit_status
