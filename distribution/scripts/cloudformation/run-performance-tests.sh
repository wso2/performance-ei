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

export wso2ei_distribution=""
export wso2ei_ec2_instance_type=""
export wso2ei_profile_type="ei"

function usageCommand() {
    echo "-e <wso2ei_distribution> -E <wso2ei_ec2_instance_type>"
}
export -f usageCommand

function usageHelp() {
    echo "-e: WSO2 Enterprise Integrator Distribution."
    echo "-E: Amazon EC2 Instance Type for WSO2 Enterprise Integrator."

}
export -f usageHelp

while getopts ":u:f:d:k:n:j:o:g:s:b:r:J:S:N:t:p:w:he:E:" opt; do
    case "${opt}" in
    e)
        wso2ei_distribution=${OPTARG}
        ;;
    E)
        wso2ei_ec2_instance_type=${OPTARG}
        ;;
    P)
        wso2ei_profile_type=${OPTARG}
        ;;
    *)
        opts+=("-${opt}")
        [[ -n "$OPTARG" ]] && opts+=("$OPTARG")
        ;;
    esac
done
shift "$((OPTIND - 1))"

function validate() {
    if [[ ! -f $wso2ei_distribution ]]; then
        if [ "$wso2ei_profile_type" == "microei" ]; then
            echo "Please provide WSO2 Enterprise Micro Integrator docker image."
        else
            echo "Please provide WSO2 Enterprise Integrator distribution."
        fi
        exit 1
    fi

    export wso2ei_distribution_filename=$(basename $wso2ei_distribution)

    if [[ ${wso2ei_distribution_filename: -4} != ".zip" ]] && ["$wso2ei_profile_type" == "ei" ]; then
        echo "WSO2 Enterprise Integrator distribution must have .zip extension"
        exit 1
    elif [[ ${wso2ei_distribution_filename: -4} != ".docker" ]] && ["$wso2ei_profile_type" == "microei" ]; then
        echo "WSO2 Enterprise Micro Integrator docker image must have .docker extension"
        exit 1
    fi

    if [[ -z $wso2ei_ec2_instance_type ]]; then
        echo "Please provide the Amazon EC2 Instance Type for WSO2 Enterprise Integrator."
        exit 1
    fi
}
export -f validate

function create_links() {
    wso2ei_distribution=$(realpath $wso2ei_distribution)
    ln -s $wso2ei_distribution $temp_dir/$wso2ei_distribution_filename
}
export -f create_links

function get_test_metadata() {
    echo "wso2ei_ec2_instance_type=$wso2ei_ec2_instance_type"
    echo "wso2ei_profile_type"=$wso2ei_profile_type
}
export -f get_test_metadata

function get_cf_parameters() {
    echo "WSO2EnterpriseIntegratorDistributionName=$wso2ei_distribution_filename"
    echo "WSO2EnterpriseIntegratorInstanceType=$wso2ei_ec2_instance_type"
    echo "WSO2EnterpriseIntegratorProfileType"=$wso2ei_profile_type
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
    echo "WSO2 Enterprise Integrator GC Throughput (%)"
    echo "Average WSO2 Enterprise Integrator Memory Footprint After Full GC (M)"
}
export -f get_columns
aws_cloudformation_template_filename="ei_perf_test_cfn.yaml"
if [[ $wso2ei_profile_type == "microei" ]]; then
    aws_cloudformation_template_filename="microei_perf_test_cfn.yaml"
fi
export aws_cloudformation_template_filename
export application_name="WSO2 Enterprise Integrator"
export metrics_file_prefix="ei"

$script_dir/cloudformation-common.sh "${opts[@]}" -- "$@"
