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

if [[ -z ${@} || ${1} == "-h" ]];then
    echo_local_test_helper_info
    exit 0
fi

TASK=${1}

TMPF=$(mktemp /tmp/.mm.XXXXXX)
clean() { rm -f ${TMPF}; }
trap clean EXIT

TMPD=$(mktemp -d /tmp/.mm.XXXXXX)
clean() { rm -f -r ${TMPD} ;}
trap clean EXIT

TEST_RUN_NIGHTLY_TESTS=""

taskdir="task/${TASK}"

# folder structure:
# /tmp/xxx/task/{version}/golang-build/...
[[ ${2} == "--nightly" ]] && TEST_RUN_NIGHTLY_TESTS=1

if [[ ! -z ${TEST_RUN_NIGHTLY_TESTS} ]];then
    git fetch --tags
    cur_branch=$(git rev-parse --abbrev-ref HEAD)

    for version_tag in $(git tag) 
    do
        git checkout "tags/${version_tag}"

        if [[ ! -d ${taskdir}/tests ]];then
            echo "No 'tests' directory is located in ${taskdir}"
            exit 1
        fi   

        version="$( echo $version_tag | tr '.' '-' )"
        kubectl get ns ${TASK}-${version//./-} >/dev/null 2>/dev/null && kubectl delete ns ${TASK}-${version//./-}

        cp_dir=${TMPD}/task/${TASK}/${version}
        mkdir -p ${cp_dir}
        cp -r ./task/${TASK}/* ${cp_dir}
    done
    git checkout ${cur_branch}
else 
    version="dev"
    kubectl get ns ${TASK}-${version//./-} >/dev/null 2>/dev/null && kubectl delete ns ${TASK}-${version//./-}

    cp_dir=${TMPD}/task/${TASK}/${version}
    mkdir -p ${cp_dir}
    cp -r ./task/${TASK}/* ${cp_dir}
fi

cd ${TMPD}

test_yaml_can_install task/${TASK}/*/tests

test_task_creation task/${TASK}/*/tests

echo 'Success'