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

export aws_cloudformation_template_filename="mi_docker_perf_test_cfn.yaml"

export application_name="WSO2 Micro Integrator"
export product_version=""
export ec2_instance_name="mi"
export metrics_file_prefix="mi"
export run_performance_tests_script_name="run-mi-docker-performance-tests.sh"

export wso2mi_ec2_instance_type=""

function usageCommand() {
    echo "-E <wso2mi_ec2_instance_type> -V <product_version>"
}
export -f usageCommand

function usageHelp() {
    echo "-E: Amazon EC2 Instance Type for $application_name."
    echo "-V: Product version for $application_name."
}
export -f usageHelp

while getopts ":u:f:d:k:n:j:o:g:s:b:r:J:S:N:t:p:w:he:E:V:" opt; do
    case "${opt}" in
    E)
        wso2mi_ec2_instance_type=${OPTARG}
        ;;
    V)
        product_version=${OPTARG}
        ;;
    *)
        opts+=("-${opt}")
        [[ -n "$OPTARG" ]] && opts+=("$OPTARG")
        ;;
    esac
done
shift "$((OPTIND - 1))"

function validate() {
    if [[ -z $wso2mi_ec2_instance_type ]]; then
        echo "Please provide the Amazon EC2 Instance Type for $application_name."
        exit 1
    fi
    if [[ -z $product_version ]]; then
        echo "Please provide the version for $application_name."
        exit 1
    fi
}
export -f validate

export application_name=$application_name" "$product_version

function get_test_metadata() {
    echo "wso2mi_ec2_instance_type=$wso2mi_ec2_instance_type"
}
export -f get_test_metadata

function get_cf_parameters() {
    echo "WSO2MicroIntegratorInstanceType=$wso2mi_ec2_instance_type"
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
