#!/usr/bin/env bash
################################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

ENTRY_POINT=$1
ARGS=("${@:2}")

bin=$(dirname "$0")
bin=$(cd "${bin}" || exit; pwd)

# get Flink config
. "${bin}"/config.sh

java_utils_output=$(runBashJavaUtilsCmd GET_JM_RESOURCE_PARAMS "${FLINK_CONF_DIR}" "${FLINK_BIN_DIR}/bash-java-utils.jar:$(findFlinkDistJar)" "${ARGS[@]}")
logging_output=$(extractLoggingOutputs "${java_utils_output}")
jvm_params=$(extractExecutionResults "${java_utils_output}" 1)
export JVM_ARGS="${JVM_ARGS} ${jvm_params}"

export FLINK_INHERITED_LOGS="
$FLINK_INHERITED_LOGS

JM_RESOURCE_PARAMS extraction logs:
jvm_params: $jvm_params
logs: $logging_output
"

if [ "$FLINK_IDENT_STRING" = "" ]; then
    FLINK_IDENT_STRING="$USER"
fi

CC_CLASSPATH=$(manglePathList "$(constructFlinkClassPath):${INTERNAL_HADOOP_CLASSPATHS}")

log="${FLINK_LOG_DIR}/flink-${FLINK_IDENT_STRING}-mesos-appmaster-${HOSTNAME}.log"
log_setting="-Dlog.file=${log} -Dlog4j.configuration=file:${FLINK_CONF_DIR}/log4j.properties -Dlog4j.configurationFile=file:${FLINK_CONF_DIR}/log4j.properties -Dlogback.configurationFile=file:${FLINK_CONF_DIR}/logback.xml"

${JAVA_RUN} ${JVM_ARGS} -classpath ${CC_CLASSPATH} ${log_setting} ${ENTRY_POINT} "${ARGS[@]}"

rc=$?

if [[ ${rc} -ne 0 ]]; then
    echo "Error while starting the mesos application master. Please check ${log} for more details."
fi

exit ${rc}
