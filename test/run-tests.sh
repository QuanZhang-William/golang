#!/usr/bin/env bash
#
# Copyright 2020 The Tekton Authors
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

set -x
set -e

cd $(git rev-parse --show-toplevel)
source $(dirname $0)/../vendor/github.com/QuanZhang-William/plumbing/scripts/verified-catalog-e2e-common.sh

TMPF=$(mktemp /tmp/.mm.XXXXXX)
clean() { rm -f ${TMPF} ;}
trap clean EXIT

if [[ -z ${@} || ${1} == "-h" ]];then
    echo_local_test_helper_info
    exit 0
fi

TASK=${1}
VERSION="dev"

taskdir=task/${TASK}

kubectl get ns ${TASK}-${VERSION//./-} >/dev/null 2>/dev/null && kubectl delete ns ${TASK}-${VERSION//./-}

if [[ ! -d ${taskdir}/tests ]];then
    echo "No 'tests' directory is located in ${taskdir}"
    exit 1
fi

test_yaml_can_install task/${TASK}/tests

test_task_creation task/${TASK}/tests

echo 'Success'
