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
# Execute common script
. $script_dir/perf-test-common.sh "${ARGS[@]}"

function initialize() {
    export ei_ssh_host=ei
    export ei_host=$(get_ssh_hostname $ei_ssh_host)
}
export -f initialize

# Include Test Scenarios
. $script_dir/performance-test-scenarios.sh

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
    ssh $ei_ssh_host "./ei/ei-start.sh -m $heap"
}

function after_execute_test_scenario() {
    ssh $ei_ssh_host "./ei/microei-stop.sh"
    write_server_metrics ei $ei_ssh_host carbon
    download_file $ei_ssh_host wso2ei/repository/logs/wso2carbon.log wso2carbon.log
    download_file $ei_ssh_host wso2ei/repository/logs/gc.log ei_gc.log
}

test_scenarios
