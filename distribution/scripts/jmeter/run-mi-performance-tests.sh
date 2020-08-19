#!/bin/bash -e
# Copyright (c) 2020, WSO2 Inc. (http://wso2.org) All Rights Reserved.
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
# Run WSO2 Micro Integrator Performance Tests
# ----------------------------------------------------------------------------
script_dir=$(dirname "$0")
# Execute common script
. $script_dir/perf-test-common.sh "${ARGS[@]}"

function initialize() {
    export mi_ssh_host=mi
    export mi_host=$(get_ssh_hostname $mi_ssh_host)
}
export -f initialize

# Include Test Scenarios
. $script_dir/performance-test-scenarios.sh

function before_execute_test_scenario() {
    local service_path=${scenario[path]}
    local protocol=${scenario[protocol]}
    local response_pattern="soapenv:Body"

    jmeter_params+=("host=$mi_host" "path=$service_path" "response_pattern=${response_pattern}")
    jmeter_params+=("response_size=${msize}B" "protocol=$protocol")

    if [[ "${scenario[name]}" == "SecureProxy" ]]; then
        jmeter_params+=("port=8253")
        jmeter_params+=("payload=$HOME/jmeter/requests/${msize}B_buyStocks_secure.xml")
    else
        jmeter_params+=("port=8290")
        jmeter_params+=("payload=$HOME/jmeter/requests/${msize}B_buyStocks.xml")
    fi

    echo "Starting Micro Integrator..."
    ssh $mi_ssh_host "./ei/mi-start.sh -m $heap"
}

function after_execute_test_scenario() {
    write_server_metrics mi $mi_ssh_host carbon
    download_file $mi_ssh_host wso2mi/repository/logs/wso2carbon.log wso2carbon.log
    download_file $mi_ssh_host wso2mi/repository/logs/gc.log mi_gc.log
}

test_scenarios
