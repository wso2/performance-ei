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
# Run performance tests on AWS Cloudformation Stacks
# ----------------------------------------------------------------------------

export script_name="$0"
export script_dir=$(dirname "$0")

export aws_cloudformation_template_filename="microei_perf_test_cfn.yaml"
export application_name="WSO2 Micro Integrator - Docker"
export ec2_instance_name="ei"
export metrics_file_prefix="ei"
export run_performance_tests_script_name="run-micro-ei-performance-tests.sh"

export wso2ei_ec2_instance_type=""

function usageCommand() {
    echo "-E <wso2ei_ec2_instance_type>"
}
export -f usageCommand

function usageHelp() {
    echo "-E: Amazon EC2 Instance Type for $application_name."
}
export -f usageHelp

while getopts ":u:f:d:k:n:j:o:g:s:b:r:J:S:N:t:p:w:he:E:" opt; do
    case "${opt}" in
    E)
        wso2ei_ec2_instance_type=${OPTARG}
        ;;
    *)
        opts+=("-${opt}")
        [[ -n "$OPTARG" ]] && opts+=("$OPTARG")
        ;;
    esac
done
shift "$((OPTIND - 1))"

function validate() {
    if [[ -z $wso2ei_ec2_instance_type ]]; then
        echo "Please provide the Amazon EC2 Instance Type for $application_name."
        exit 1
    fi
}
export -f validate

function get_test_metadata() {
    echo "wso2ei_ec2_instance_type=$wso2ei_ec2_instance_type"
}
export -f get_test_metadata

function get_cf_parameters() {
    echo "WSO2EnterpriseIntegratorInstanceType=$wso2ei_ec2_instance_type"
}
export -f get_cf_parameters

function get_columns() {
    echo "Scenario Name"
    echo "Heap Size"
    echo "Concurrent Users"
    echo "Message Size (Bytes)"
    echo "Back-end Service Delay (ms)"
    echo "Error %"
    echo "Throughput (Requests/sec)"
    echo "Average Response Time (ms)"
    echo "Standard Deviation of Response Time (ms)"
    echo "99th Percentile of Response Time (ms)"
    echo "$application_name GC Throughput (%)"
    echo "Average $application_name Memory Footprint After Full GC (M)"
}
export -f get_columns

$script_dir/cloudformation-common.sh "${opts[@]}" -- "$@"
