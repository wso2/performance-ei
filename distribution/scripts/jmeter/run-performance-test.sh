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
# Run Performance Tests for WSO2 Enterprise Integrator
# ----------------------------------------------------------------------------
script_dir=$(dirname "$0")

# Postfix symbol for message size (B = bytes)
payload_size_postfix="B"

# Message Sizes in bytes for sample payloads
default_message_sizes="500 1024 5120 10240 102400 512000"
declare -a message_sizes

# Concurrent users (these will by multiplied by the number of JMeter servers)
default_concurrent_users="50 100 150 500 1000"
declare -a concurrent_users

# Common backend sleep times (in milliseconds).
default_backend_sleep_times="0 30 500 1000"
declare -a backend_sleep_times

# Application heap Sizes
default_heap_sizes="2G"
declare -a heap_sizes

# Test Duration in seconds
default_test_duration=900
test_duration=$default_test_duration

# Warm-up time in seconds
default_warmup_time=300
warmup_time=$default_warmup_time

# JMeter Servers
# If jmeter_servers = 1, only client will be used. If jmeter_servers > 1, remote JMeter servers will be used.
default_jmeter_servers=1
jmeter_servers=$default_jmeter_servers

# Heap size of JMeter Client
default_jmeter_client_heap_size=2G
jmeter_client_heap_size=$default_jmeter_client_heap_size

# Heap size of JMeter Server
default_jmeter_server_heap_size=4G
jmeter_server_heap_size=$default_jmeter_server_heap_size

# Heap size of Netty Service
default_netty_service_heap_size=4G
netty_service_heap_size=$default_netty_service_heap_size

# Estimated processing time in between tests
default_estimated_processing_time_in_between_tests=60
estimated_processing_time_in_between_tests=$default_estimated_processing_time_in_between_tests

# Scenario names to include
declare -a include_scenario_names

# Scenario names to exclude
declare -a exclude_scenario_names

function usage() {
    echo ""
    echo "Usage: "
    echo "$0 [-u <concurrent_users>] [-b <message_sizes>] [-s <sleep_times>] [-m <heap_sizes>] [-d <test_duration>] [-w <warmup_time>]"
    echo "   [-n <jmeter_servers>] [-j <jmeter_server_heap_size>] [-k <jmeter_client_heap_size>] [-l <netty_service_heap_size>]"
    echo "   [-i <include_scenario_name>] [-e <include_scenario_name>] [-t] [-p <estimated_processing_time_in_between_tests>] [-h]"
    echo ""
    echo "-u: Concurrent Users to test. You can give multiple options to specify multiple users. Default \"$default_concurrent_users\"."
    echo "-b: Message sizes in bytes. You can give multiple options to specify multiple message sizes. Default \"$default_message_sizes\"."
    echo "-s: Backend Sleep Times in milliseconds. You can give multiple options to specify multiple sleep times. Default \"$default_backend_sleep_times\"."
    echo "-m: Application heap memory sizes. You can give multiple options to specify multiple heap memory sizes. Allowed suffixes: M, G. Default \"$default_heap_sizes\"."
    echo "-d: Test Duration in seconds. Default $default_test_duration."
    echo "-w: Warm-up time in seconds. Default $default_warmup_time."
    echo "-n: Number of JMeter servers. If n=1, only client will be used. If n > 1, remote JMeter servers will be used. Default $default_jmeter_servers."
    echo "-j: Heap Size of JMeter Server. Allowed suffixes: M, G. Default $default_jmeter_server_heap_size."
    echo "-k: Heap Size of JMeter Client. Allowed suffixes: M, G. Default $default_jmeter_client_heap_size."
    echo "-l: Heap Size of Netty Service. Allowed suffixes: M, G. Default $default_netty_service_heap_size."
    echo "-i: Scenario name to to be included. You can give multiple options to filter scenarios."
    echo "-e: Scenario name to to be excluded. You can give multiple options to filter scenarios."
    echo "-p: Estimated processing time in between tests in seconds. Default $default_estimated_processing_time_in_between_tests."
    echo "-h: Display this help and exit."
    echo ""
}

while getopts "u:b:s:m:d:w:n:j:k:l:i:e:tp:h" opts; do
    case $opts in
    u)
        concurrent_users+=("${OPTARG}")
        ;;
    b)
        message_sizes+=("${OPTARG}")
        ;;
    s)
        backend_sleep_times+=("${OPTARG}")
        ;;
    m)
        heap_sizes+=("${OPTARG}")
        ;;
    d)
        test_duration=${OPTARG}
        ;;
    w)
        warmup_time=${OPTARG}
        ;;
    n)
        jmeter_servers=${OPTARG}
        ;;
    j)
        jmeter_server_heap_size=${OPTARG}
        ;;
    k)
        jmeter_client_heap_size=${OPTARG}
        ;;
    l)
        netty_service_heap_size=${OPTARG}
        ;;
    i)
        include_scenario_names+=("${OPTARG}")
        ;;
    e)
        exclude_scenario_names+=("${OPTARG}")
        ;;
    p)
        estimated_processing_time_in_between_tests=${OPTARG}
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

if [ ${#heap_sizes[@]} -eq 0 ]; then
    heap_sizes=$default_heap_sizes
fi

if [ ${#concurrent_users[@]} -eq 0 ]; then
    concurrent_users=$default_concurrent_users
fi

if [ ${#message_sizes[@]} -eq 0 ]; then
    message_sizes=$default_message_sizes
fi

if [ ${#backend_sleep_times[@]} -eq 0 ]; then
    backend_sleep_times=$default_backend_sleep_times
fi

# Execute common script
. $script_dir/perf-test-common.sh -u $concurrent_users -b $message_sizes -s $backend_sleep_times -m $heap_sizes \
-d $test_duration -w $warmup_time -n $jmeter_servers -j $jmeter_server_heap_size -k $jmeter_client_heap_size \
-l $netty_service_heap_size -i $include_scenario_names -e $exclude_scenario_names \
-p $estimated_processing_time_in_between_tests

function initialize() {
    export ei_ssh_host=ei
    export ei_host=$(get_ssh_hostname $ei_ssh_host)
}
export -f initialize

# Default product name
product=wso2ei
# Default heap size
heap_size=2

# Test scenarios
declare -A test_scenario0=(
    [name]="DirectProxy"
    [path]="/services/DirectProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario1=(
    [name]="CBRProxy"
    [path]="/services/CBRProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario2=(
    [name]="CBRSOAPHeaderProxy"
    [path]="/services/CBRSOAPHeaderProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario3=(
    [name]="CBRTransportHeaderProxy"
    [path]="/services/CBRTransportHeaderProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario4=(
    [name]="SecureProxy"
    [path]="/services/SecureProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="https"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario5=(
    [name]="XSLTEnhancedProxy"
    [path]="/services/XSLTEnhancedProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=false
    [skip]=false
)
declare -A test_scenario10=(
    [name]="XSLTProxy"
    [path]="/services/XSLTProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=true
)

# Verifying if payloads for each message size exists in the 'requests' directory
function verifyRequestPayloads() {
    for i in $message_sizes
    do
        i+=$payload_size_postfix
        if ! ls requests/$i* 1> /dev/null 2>&1; then
            echo "Test payload for size: $i is missing"
            exit 1
        fi
    done
}
verifyRequestPayloads

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

    echo "Starting Enterprise Integrator..."
    ssh $ei_ssh_host "./ei/ei-start.sh -p $product -s $heap_size"
}

function after_execute_test_scenario() {
    write_server_metrics ei $ei_ssh_host carbon
}

test_scenarios
