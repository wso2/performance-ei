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
declare -a available_message_iterations=("5" "10" "20" "50" "100")

# Verifying if payloads for each message size exists in the 'requests' directory
function verifyRequestPayloads() {
    for i in "$@"; do
        if ! ls $script_dir/requests/${i}B_buyStocks*.xml 1>/dev/null 2>&1; then
            echo "ERROR: Payload file for $i bytes is missing!"
            exit 1
        fi
    done
}

# Verifying if payloads for each message size exists in the 'requests' directory
function verifyIteratePayloads() {
    for i in "$@"; do
        if ! ls $script_dir/requests/${i}Elements_buyStocks*.xml 1>/dev/null 2>&1; then
            echo "ERROR: Payload file for $i elements is missing!"
            exit 1
        fi
    done
}

verifyRequestPayloads "${available_message_sizes[@]}"
verifyRequestPayloads "${message_sizes_array[@]}"

verifyIteratePayloads "${message_iteratations_array[@]}"
verifyIteratePayloads "${message_iteratations_array[@]}"

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
declare -A test_scenario12=(
    [name]="MessageBuildingProxy"
    [display_name]="Message Building Proxy"
    [description]="Message Building Proxy service"
    [path]="/services/MessageBuildingProxy"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario14=(
    [name]="CloneAndAggregateWithTwoBackendProxy"
    [display_name]="Clone & Aggregate With 2 Backend Proxy"
    [description]="Clone payload and send to 2 backends and aggregate the response back"
    [path]="/services/CloneAndAggregateWithTwoBackendProxy"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario15=(
    [name]="CloneAndAggregateWithFourBackendProxy"
    [display_name]="Clone & Aggregate With 4 Backend Proxy"
    [description]="Clone payload and send to 4 backends and aggregate the response back"
    [path]="/services/CloneAndAggregateWithTwoBackendProxy"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario16=(
    [name]="CloneAndAggregateWithEightBackendProxy"
    [display_name]="Clone & Aggregate With 8 Backend Proxy"
    [description]="Clone payload and send to 8 backends and aggregate the response back"
    [path]="/services/CloneAndAggregateWithTwoBackendProxy"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario17=(
    [name]="EnrichBackAndForthProxy"
    [display_name]="Enrich Back & Forth Proxy"
    [description]="Enrich payload to a property and enrich back in the response"
    [path]="/services/EnrichBackAndForthProxy"
    [jmx]="ei-test.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario18=(
    [name]="IterateAndAggregateProxy"
    [display_name]="Iterate and Aggregate Proxy"
    [description]="Iterate over a payload and call backend and aggregate the response"
    [path]="/services/IterateAndAggregateProxy"
    [jmx]="ei-test-without-soap.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario19=(
    [name]="XSLTTransformProxy"
    [display_name]="XSLT Transform Proxy"
    [description]="Do a XSLT Transformation"
    [path]="/services/XSLTTransformProxy"
    [jmx]="ei-test-without-soap.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario20=(
    [name]="DatamapperProxy"
    [display_name]="Datamapper Transform Proxy"
    [description]="Do a XML transformation same as XSLTTransformProxy"
    [path]="/services/DatamapperProxy"
    [jmx]="ei-test-without-soap.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario21=(
    [name]="PayloadFactoryWith20ElementsProxy"
    [display_name]="PayloadFactory with 20 Elements Proxy"
    [description]="Do a XML transformation same as XSLTTransformProxy"
    [path]="/services/PayloadFactoryWith20ElementsProxy"
    [jmx]="ei-test-without-soap.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario22=(
    [name]="PayloadFactoryWith50ElementsProxy"
    [display_name]="PayloadFactory with 50 Elements Proxy"
    [description]="Do a XML transformation same as XSLTTransformProxy"
    [path]="/services/PayloadFactoryWith50ElementsProxy"
    [jmx]="ei-test-without-soap.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario23=(
    [name]="PayloadFactoryWith100ElementsProxy"
    [display_name]="PayloadFactory with 100 Elements Proxy"
    [description]="Do a XML transformation same as XSLTTransformProxy"
    [path]="/services/PayloadFactoryWith100ElementsProxy"
    [jmx]="ei-test-without-soap.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario24=(
    [name]="JsonToSOAPProxy"
    [display_name]="JSON to SOAP Transformation"
    [description]="Convert JSON payload to SOAP format and send to the back end"
    [path]="/services/JsonToSOAPProxy"
    [jmx]="ei-test-json.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario25=(
    [name]="DirectHTTPSAPI"
    [display_name]="Direct HTTPS API"
    [description]="Passthrough API HTTPS service"
    [path]="/directApi"
    [jmx]="ei-test.jmx"
    [protocol]="https"
    [use_backend]=true
    [skip]=false
)

