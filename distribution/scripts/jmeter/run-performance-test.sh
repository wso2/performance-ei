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

if [[ -d results ]]; then
    echo "Results directory already exists"
    exit 1
fi

script_dir=$(dirname "$0")
jmeter_dir=""
for dir in $HOME/apache-jmeter*; do
    [ -d "${dir}" ] && jmeter_dir="${dir}" && break
done
export JMETER_HOME="${jmeter_dir}"
export PATH=$JMETER_HOME/bin:$PATH

validate_command() {
    # Check whether given command exists
    # $1 is the command name
    # $2 is the package containing command
    if ! command -v $1 >/dev/null 2>&1; then
        echo "Please install $2 (sudo apt -y install $2)"
        exit 1
    fi
}

validate_command zip zip
#jq is required to create final reports
validate_command jq jq

product="wso2ei-6.1.1"
concurrent_users=(50 100 150 500 1000)
backend_sleep_time=(0 30 500 1000)
proxy_types=(DirectProxy CBRProxy CBRSOAPHeaderProxy CBRTransportHeaderProxy SecureProxy XSLTEnhancedProxy XSLTProxy)
request_payloads=(500B_buyStocks.xml 1K_buyStocks.xml 5K_buyStocks.xml 10K_buyStocks.xml 100K_buyStocks.xml)
secure_payloads=(500B_buyStocks_secure.xml 1K_buyStocks_secure.xml 5K_buyStocks_secure.xml 10K_buyStocks_secure.xml 100K_buyStocks_secure.xml)
ei_host=172.30.2.239
ei_ssh_host=ei
backend_ssh_host=netty
netty_port=9000
# Test Duration in seconds
test_duration=900
# Warm-up time in minutes
warmup_time=5
jmeter1_host=172.30.2.13
jmeter2_host=172.30.2.46
jmeter1_ssh_host=jmeter1
jmeter2_ssh_host=jmeter2
#Heap Size in GBs
heap_size=4
mkdir results
cp $0 results

write_server_metrics() {
    server=$1
    ssh_host=$2
    pgrep_pattern=$3
    command_prefix=""
    if [[ ! -z $ssh_host ]]; then
        command_prefix="ssh $ssh_host"
    fi
    $command_prefix ss -s > ${report_location}/${server}_ss.txt
    $command_prefix uptime > ${report_location}/${server}_uptime.txt
    $command_prefix sar -q > ${report_location}/${server}_loadavg.txt
    $command_prefix sar -A > ${report_location}/${server}_sar.txt
    $command_prefix top -bn 1 > ${report_location}/${server}_top.txt
    if [[ ! -z $pgrep_pattern ]]; then
        $command_prefix ps u -p \`pgrep -f $pgrep_pattern\` > ${report_location}/${server}_ps.txt
    fi
}

for proxy_type in ${proxy_types[@]}
do
    payloads=("${request_payloads[@]}")
    if [[ $proxy_type == "SecureProxy" ]]; then
        payloads=("${secure_payloads[@]}")
    fi
    for payload in ${payloads[@]}
    do
        for sleep_time in ${backend_sleep_time[@]}
        do
            for u in ${concurrent_users[@]}
            do
                # There are two JMeter Servers
                total_users=$(($u * 2))
                msg_size=$(echo $payload | cut -d_ -f1)
                report_location=$PWD/results/${proxy_type}/${msg_size}/${sleep_time}ms_sleep/${total_users}_users
                echo "Report location is ${report_location}"
                mkdir -p $report_location

                ssh $ei_ssh_host "./ei/ei-start.sh $product $heap_size"
                ssh $backend_ssh_host "./netty-service/netty-start.sh $sleep_time $netty_port"

                # Start remote JMeter servers
                ssh $jmeter1_ssh_host "./jmeter/jmeter-server-start.sh $jmeter1_host"
                ssh $jmeter2_ssh_host "./jmeter/jmeter-server-start.sh $jmeter2_host"

                export JVM_ARGS="-Xms2g -Xmx2g -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:$report_location/jmeter_gc.log"
                echo "# Running JMeter. Concurrent Users: $u Duration: $test_duration JVM Args: $JVM_ARGS"
                jmeter -n -t ei-test.jmx -R $jmeter1_host,$jmeter2_host -X \
                    -Gusers=$u -Gduration=$test_duration -Ghost=$ei_host -Gpath=/services/$proxy_type \
                    -Gpayload=$HOME/jmeter/requests/${payload} \
                    -Gprotocol=http -Gport=8280 -l ${report_location}/results.jtl

                write_server_metrics jmeter
                write_server_metrics ei $ei_ssh_host carbon
                write_server_metrics netty $backend_ssh_host netty
                write_server_metrics jmeter1 $jmeter1_ssh_host
                write_server_metrics jmeter2 $jmeter2_ssh_host

                $HOME/jtl-splitter/jtl-splitter.sh ${report_location}/results.jtl $warmup_time
                echo "Generating Dashboard for Warmup Period"
                jmeter -g ${report_location}/results-warmup.jtl -o $report_location/dashboard-warmup
                echo "Generating Dashboard for Measurement Period"
                jmeter -g ${report_location}/results-measurement.jtl -o $report_location/dashboard-measurement

                echo "Zipping JTL files in ${report_location}"
                zip -jm ${report_location}/jtls.zip ${report_location}/results*.jtl

                scp $jmeter1_ssh_host:jmetergc.log ${report_location}/jmeter1_gc.log
                scp $jmeter2_ssh_host:jmetergc.log ${report_location}/jmeter2_gc.log
                scp $ei_ssh_host:$product/repository/logs/wso2carbon.log ${report_location}/wso2carbon.log
                scp $ei_ssh_host:$product/repository/logs/gc.log ${report_location}/ei_gc.log
                scp $backend_ssh_host:netty-service/logs/netty.log ${report_location}/netty.log
                scp $backend_ssh_host:netty-service/logs/nettygc.log ${report_location}/netty_gc.log
            done
        done
    done
done

echo "Completed"