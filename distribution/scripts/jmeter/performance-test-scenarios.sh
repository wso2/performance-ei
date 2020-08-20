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
# Performance Test Scenarios
# ----------------------------------------------------------------------------

# Message Sizes in bytes for sample payloads
declare -a available_message_sizes=("500" "1000" "10000" "100000" "200000" "500000" "1000000")

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

# Test scenarios
declare -A test_scenario0=(
    [name]="DirectProxy"
    [display_name]="Direct Proxy"
    [description]="Passthrough proxy service"
    [path]="/services/DirectProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario1=(
    [name]="CBRProxy"
    [display_name]="CBR Proxy"
    [description]="Routing the message based on the content of the message body"
    [path]="/services/CBRProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario2=(
    [name]="CBRSOAPHeaderProxy"
    [display_name]="CBR SOAP Header Proxy"
    [description]="Routing the message based on a SOAP header in the message payload"
    [path]="/services/CBRSOAPHeaderProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario3=(
    [name]="CBRTransportHeaderProxy"
    [display_name]="CBR Transport Header Proxy"
    [description]="Routing the message based on an HTTP header in the message"
    [path]="/services/CBRTransportHeaderProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario4=(
    [name]="SecureProxy"
    [display_name]="Secure Proxy"
    [description]="Secured proxy service"
    [path]="/services/SecureProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="https"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario5=(
    [name]="XSLTEnhancedProxy"
    [display_name]="XSLT Enhanced Proxy"
    [description]="Having enhanced, Fast XSLT transformations in request and response paths"
    [path]="/services/XSLTEnhancedProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario10=(
    [name]="XSLTProxy"
    [display_name]="XSLT Proxy"
    [description]="Having XSLT transformations in request and response paths"
    [path]="/services/XSLTProxy/buyStocksOperation"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario11=(
    [name]="DirectAPI"
    [display_name]="Direct API"
    [description]="Passthrough API service"
    [path]="/directApi"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
