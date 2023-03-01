#!/bin/bash

# Copyright 2022 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Processes sap_config.env file
# by reading values to the corresponding Cloud Build substitution variables:
# _DEPLOY_CDC, _GEN_EXT, _LOCATION,
# _PJID_SRC, _DS_RAW, _PJID_TGT, _DS_CDC, _TEST_DATA, _SQL_FLAVOUR
# _GCS_LOG_BUCKET (GCS_BUCKET from Data Foundation), _GCS_BUCKET (TGT_BUCKET from Data Foundation)

CONFIG_FILE="config/sap_config.env"

apply_config(){
    config_file_path=$1
    eval $(cat ${config_file_path} | sed -e 's/^[ \t]*//;s/[ \t]*$//;/^#/d;/^\s*$/d;s#\([^\]\)"#\1#g;s/=\(.*\)/=\"\1\"/g;s/^/export /;s/$/;/')
}

make_defaults(){
}

# Converting Cloud Build substitutions to env variables.
export _PJID_SRC_="${1}"; export _PJID_TGT_="${2}";
export _GCS_LOG_BUCKET_="${3}"; export _GCS_BUCKET_="${4}"; 
export _DS_CDC_="${5}"; export _DS_CDC_SEC_="${6}"; 
export _DEPLOY_CDC_="${7}";

if [ -f "${CONFIG_FILE}" ]
then
    echo -e "\n======== 🔪🔪🔪 Found Configuration ${CONFIG_FILE} 🔪🔪🔪 ========"
    cat "${CONFIG_FILE}"
    echo "============================================"
    apply_config "${CONFIG_FILE}"
else
    # No config.env, nothing to process.
    make_defaults
    exit 0
fi

if [[ "${_GCS_LOG_BUCKET_}" == "" ]]
then
    # GCS_BUCKET in Data Foundation sap_config.env is the log bucket
    if [[ "${GCS_BUCKET}" != "" ]]
    then
        export _GCS_LOG_BUCKET_="${GCS_BUCKET}"
    else
        echo "No Build Logs Bucket name provided."
        cloud_build_project=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
        export _GCS_LOG_BUCKET_="${cloud_build_project}_cloudbuild"
        export GCS_BUCKET="${_GCS_LOG_BUCKET_}"
        echo "Using ${_GCS_LOG_BUCKET_}"
    fi
fi

# Provision substitution variables.
# Only change a variable if it's empty.
# It's usually empty if not passed to the Cloud Build.
# If passed to the cloud build, don't change it,
# copy the value to the config variable instead.

if [[ "${_PJID_SRC_}" == "" ]]
then
    export _PJID_SRC_="${PJID_SRC}"
else
    export PJID_SRC="${_PJID_SRC_}"
fi

if [[ "${_PJID_TGT_}" == "" ]]
then
    export _PJID_TGT_="${PJID_TGT}"
else
    export PJID_TGT="${_PJID_TGT_}"
fi

if [[ "${_DS_CDC_}" == "" ]]
then
    export _DS_CDC_="${DS_CDC}"
else
    export DS_CDC="${_DS_CDC_}"
fi

if [[ "${_DS_CDC_SEC_}" == "" ]]
then
    export _DS_CDC_SEC_="${DS_CDC_SEC}"
else
    export DS_CDC_SEC="${_DS_CDC_SEC_}"
fi

# _GCS_BUCKET in CDC Cloud Build is TGT_BUCKET from Data Foundation
if [[ "${_GCS_BUCKET_}" == "" ]]
then
    export _GCS_BUCKET_="${TGT_BUCKET}"
else
    export TGT_BUCKET="${_GCS_BUCKET_}"
fi

if [[ "${_DEPLOY_CDC_}" == "" ]]
then
    export _DEPLOY_CDC_="${DEPLOY_CDC}"
else
    export DEPLOY_CDC="${_DEPLOY_CDC_}"
fi

make_defaults