#!/bin/bash -e
# Copyright (c) 2018, WSO2 Inc. (http://wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------
# Run WSO2 Enterprise Integrator Performance Tests
# ----------------------------------------------------------------------------
script_dir=$(dirname "$0")

ARGS=()
for var in "$@"; do
    # Ignore ei profile,num of cpu arguments for common script
    [ "$var" != '-P' ] && [ "$var" != '-c' ] && ARGS+=("$var")
done

# Execute common script
. $script_dir/perf-test-common.sh "${ARGS[@]}"

wso2ei_profile_type="ei"
num_of_cpus=""

function usageHelp() {
    echo "-P: Heap memory size. Default value: $default_heap_size"
    echo "-c: Number of cpus allocated. Default value: $num_of_cpus"
}
export -f usageHelp

while getopts "P:c:h" opts; do
    case $opts in
    P)
        wso2ei_profile_type=${OPTARG}
        ;;
    c)
        num_of_cpus=${OPTARG}
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

# Message Sizes in bytes for sample payloads
declare -a available_message_sizes=("500" "1024" "5120" "10240" "102400" "512000")

# Verifying if payloads for each message size exists in the 'requests' directory
function verifyRequestPayloads() {
    for i in "$@"; do
        if ! ls $script_dir/requests/${i}B_buyStocks*.xml 1>/dev/null 2>&1; then
            echo "ERROR: Payload file for $i bytes is missing!"
            exit 1
        fi
    done
}

verifyRequestPayloads "${available_message_sizes[@]}"
verifyRequestPayloads "${message_sizes_array[@]}"

function initialize() {
    export ei_ssh_host=ei
    export ei_host=$(get_ssh_hostname $ei_ssh_host)
}
export -f initialize

# Test scenarios
declare -A test_scenario0=(
    [name]="DirectProxy"
    [display_name]="DirectProxy"
    [path]="/services/DirectProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario1=(
    [name]="CBRProxy"
    [display_name]="CBRProxy"
    [path]="/services/CBRProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario2=(
    [name]="CBRSOAPHeaderProxy"
    [display_name]="CBRSOAPHeaderProxy"
    [path]="/services/CBRSOAPHeaderProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario3=(
    [name]="CBRTransportHeaderProxy"
    [display_name]="CBRTransportHeaderProxy"
    [path]="/services/CBRTransportHeaderProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario4=(
    [name]="SecureProxy"
    [display_name]="SecureProxy"
    [path]="/services/SecureProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="https"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario5=(
    [name]="XSLTEnhancedProxy"
    [display_name]="XSLTEnhancedProxy"
    [path]="/services/XSLTEnhancedProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario10=(
    [name]="XSLTProxy"
    [display_name]="XSLTProxy"
    [path]="/services/XSLTProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)

function before_execute_test_scenario() {
    local service_path=${scenario[path]}
    local protocol=${scenario[protocol]}
    local response_pattern="soapenv:Body"

    jmeter_params+=("host=$ei_host" "path=$service_path" "response_pattern=${response_pattern}")
    jmeter_params+=("response_size=${msize}B" "protocol=$protocol")

    if [[ "${scenario[name]}" == "SecureProxy" ]]; then
        jmeter_params+=("port=8243")
        jmeter_params+=("payload=$HOME/jmeter/requests/${msize}B_buyStocks_secure.xml")
    else
        jmeter_params+=("port=8280")
        jmeter_params+=("payload=$HOME/jmeter/requests/${msize}B_buyStocks.xml")
    fi
    if [ "$wso2ei_profile_type" == "microei" ]; then
        echo "Starting Enterprise Micro Integrator..."
        ssh $ei_ssh_host "./ei/microei-start.sh -m $heap -c $num_of_cpus"
    else
        echo "Starting Enterprise Integrator..."
        ssh $ei_ssh_host "./ei/ei-start.sh -m $heap"
    fi
}

function after_execute_test_scenario() {
    ssh $ei_ssh_host "./ei/microei-stop.sh"
    write_server_metrics ei $ei_ssh_host carbon
    if [ "${wso2ei_profile_type}" == "microei" ]; then
        download_file $ei_ssh_host logs/wso2carbon.log wso2carbon.log
        download_file $ei_ssh_host logs/gc.log ei_gc.log
    else
        download_file $ei_ssh_host wso2ei/repository/logs/wso2carbon.log wso2carbon.log
        download_file $ei_ssh_host wso2ei/repository/logs/gc.log ei_gc.log
    fi
}

test_scenarios
