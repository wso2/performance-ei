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
    local response_pattern="symbol"

    jmeter_params+=("host=$mi_host" "path=$service_path" "response_pattern=${response_pattern}")
    jmeter_params+=("response_size=${msize}B" "protocol=$protocol")

    if [[ "${scenario[name]}" == "SecureProxy" ]]; then
        jmeter_params+=("port=8253")
        jmeter_params+=("payload=$HOME/jmeter/requests/${msize}B_buyStocks_secure.xml")
    elif [[ "${scenario[name]}" == "XSLTTransformProxy" || "${scenario[name]}" == "DatamapperProxy" || "${scenario[name]}" == "IterateAndAggregateProxy" ]]; then
        jmeter_params+=("port=8290")
        jmeter_params+=("payload=$HOME/jmeter/requests/${iteratecount}Elements_buyStocks.xml")
    elif [[ "${scenario[name]}" == "PayloadFactoryWith20ElementsProxy" ]]; then
        jmeter_params+=("port=8290")
        jmeter_params+=("payload=$HOME/jmeter/requests/20Elements_buyStocks.xml")
    elif [[ "${scenario[name]}" == "PayloadFactoryWith50ElementsProxy" ]]; then
        jmeter_params+=("port=8290")
        jmeter_params+=("payload=$HOME/jmeter/requests/50Elements_buyStocks.xml")
    elif [[ "${scenario[name]}" == "PayloadFactoryWith100ElementsProxy" ]]; then
        jmeter_params+=("port=8290")
        jmeter_params+=("payload=$HOME/jmeter/requests/100Elements_buyStocks.xml")
     elif [[ "${scenario[name]}" == "JsonToSOAPProxy" ]]; then
        jmeter_params+=("port=8290")
        jmeter_params+=("payload=$HOME/jmeter/requests/${msize}B_JSONPayload.json")
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

function test_scenarios_with_iterate_elements() {
    initialize_test
    local test_counter=0
    for heap in ${heap_sizes_array[@]}; do
        declare -ng scenario
        for scenario in ${!test_scenario@}; do
            local skip=${scenario[skip]}
            if [ $skip = true ]; then
                continue
            fi
            local scenario_name=${scenario[name]}
            local jmx_file=${scenario[jmx]}
            declare -a sleep_times_array
            if [ ${scenario[use_backend]} = true ]; then
                sleep_times_array=("${backend_sleep_times_array[@]}")
            else
                sleep_times_array=("-1")
            fi
            for users in ${concurrent_users_array[@]}; do
                for iteratecount in ${message_iteratations_array[@]}; do
                    for sleep_time in ${sleep_times_array[@]}; do
                        if [ "$estimate" = true ]; then
                            record_scenario_duration $scenario_name $(($test_duration + $estimated_processing_time_in_between_tests))
                            continue
                        fi
                        local start_time=$(date +%s)
                        #requests served by multiple jmeter servers if $jmeter_servers > 1
                        local users_per_jmeter=$(bc <<<"scale=0; ${users}/${jmeter_servers}")

                        test_counter=$((test_counter + 1))
                        local scenario_desc="Test No: ${test_counter}, Scenario Name: ${scenario_name}, Duration: $test_duration"
                        scenario_desc+=", Concurrent Users ${users}, Msg Iterate Count: ${iteratecount}, Sleep Time: ${sleep_time}"
                        echo -n "# Starting the performance test."
                        echo " $scenario_desc"

                        report_location=$PWD/results/${scenario_name}/${heap}_heap/${users}_users/${iteratecount}/${sleep_time}ms_sleep

                        echo "Report location is ${report_location}"
                        mkdir -p $report_location

                        if [[ $sleep_time -ge 0 ]]; then
                            local backend_flags="${scenario[backend_flags]}"
                            echo "Starting Backend Service. Delay: $sleep_time, Additional Flags: ${backend_flags:-N/A}"
                            ssh $backend_ssh_host "./netty-service/netty-start.sh -m $netty_service_heap_size -w \
                                -- ${backend_flags} --delay $sleep_time"
                            collect_server_metrics netty $backend_ssh_host netty
                        fi

                        declare -ag jmeter_params=("users=$users_per_jmeter" "duration=$test_duration")

                        before_execute_test_scenario

                        if [[ $jmeter_servers -gt 1 ]]; then
                            echo "Starting Remote JMeter servers"
                            for ix in ${!jmeter_ssh_hosts[@]}; do
                                echo "Starting Remote JMeter server. SSH Host: ${jmeter_ssh_hosts[ix]}, IP: ${jmeter_hosts[ix]}, Path: $HOME, Heap: $jmeter_server_heap_size"
                                ssh ${jmeter_ssh_hosts[ix]} "./jmeter/jmeter-server-start.sh -n ${jmeter_hosts[ix]} -i $HOME -m $jmeter_server_heap_size -- $JMETER_JVM_ARGS"
                                collect_server_metrics ${jmeter_ssh_hosts[ix]} ${jmeter_ssh_hosts[ix]} ApacheJMeter.jar
                            done
                        fi

                        export JVM_ARGS="-Xms$jmeter_client_heap_size -Xmx$jmeter_client_heap_size -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:$report_location/jmeter_gc.log $JMETER_JVM_ARGS"

                        local jmeter_command="jmeter -n -t $script_dir/${jmx_file} -j $report_location/jmeter.log $jmeter_remote_args"
                        if [[ $jmeter_servers -gt 1 ]]; then
                            jmeter_command+=" -R $(
                                IFS=","
                                echo "${jmeter_hosts[*]}"
                            ) -X"
                            for param in ${jmeter_params[@]}; do
                                jmeter_command+=" -G$param"
                            done
                        else
                            for param in ${jmeter_params[@]}; do
                                jmeter_command+=" -J$param"
                            done
                        fi
                        jmeter_command+=" -l ${report_location}/results.jtl"

                        echo "Starting JMeter Client with JVM_ARGS=$JVM_ARGS"
                        echo "$jmeter_command"

                        # Start timestamp
                        test_start_timestamp=$(date +%s)
                        echo "Start timestamp: $test_start_timestamp"
                        # Run JMeter in background
                        $jmeter_command &
                        collect_server_metrics jmeter ApacheJMeter.jar
                        local jmeter_pid="$!"
                        if ! wait $jmeter_pid; then
                            echo "WARNING: JMeter execution failed."
                        fi
                        # End timestamp
                        test_end_timestamp="$(date +%s)"
                        echo "End timestamp: $test_end_timestamp"

                        local test_duration_file="${report_location}/test_duration.json"
                        if jq -n --arg start_timestamp "$test_start_timestamp" \
                            --arg end_timestamp "$test_end_timestamp" \
                            --arg test_duration "$(($test_end_timestamp - $test_start_timestamp))" \
                            '. | .["start_timestamp"]=$start_timestamp | .["end_timestamp"]=$end_timestamp | .["test_duration"]=$test_duration' >$test_duration_file; then
                            echo "Wrote test start timestamp, end timestamp and test duration to $test_duration_file."
                        fi

                        write_server_metrics jmeter ApacheJMeter.jar
                        if [[ $jmeter_servers -gt 1 ]]; then
                            for jmeter_ssh_host in ${jmeter_ssh_hosts[@]}; do
                                write_server_metrics $jmeter_ssh_host $jmeter_ssh_host ApacheJMeter.jar
                            done
                        fi
                        if [[ $sleep_time -ge 0 ]]; then
                            write_server_metrics netty $backend_ssh_host netty
                        fi

                        if [[ -f ${report_location}/results.jtl ]]; then
                            # Delete the original JTL file to save space.
                            # Can merge files using the command: awk 'FNR==1 && NR!=1{next;}{print}'
                            # However, the merged file may not be same as original and that should be okay
                            $HOME/jtl-splitter/jtl-splitter.sh -- -f ${report_location}/results.jtl -d -t $warmup_time -u SECONDS -s
                            echo "Zipping JTL files in ${report_location}"
                            zip -jm ${report_location}/jtls.zip ${report_location}/results*.jtl
                        fi

                        if [[ $sleep_time -ge 0 ]]; then
                            download_file $backend_ssh_host netty-service/logs/netty.log netty.log
                            download_file $backend_ssh_host netty-service/logs/nettygc.log netty_gc.log
                        fi
                        if [[ $jmeter_servers -gt 1 ]]; then
                            for jmeter_ssh_host in ${jmeter_ssh_hosts[@]}; do
                                download_file $jmeter_ssh_host jmetergc.log ${jmeter_ssh_host}_gc.log
                                download_file $jmeter_ssh_host server.out ${jmeter_ssh_host}_server.out
                                download_file $jmeter_ssh_host jmeter-server.log ${jmeter_ssh_host}_server.log
                            done
                        fi

                        after_execute_test_scenario

                        local current_execution_duration="$(measure_time $start_time)"
                        echo -n "# Completed the performance test."
                        echo " $scenario_desc"
                        echo -e "Test execution time: $(format_time $current_execution_duration)\n"
                        record_scenario_duration $scenario_name $current_execution_duration
                    done
                done
            done
        done
    done
}

if [ ${#message_iteratations_array[@]} -eq 0 ]; then
    test_scenarios
else 
    test_scenarios_with_iterate_elements
fi
