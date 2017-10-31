#!/bin/bash -eu

if [ "${DEBUG:=false}" = "true" ]; then
  set -o xtrace
fi
DRY_RUN="${DRY_RUN:=false}"

usage() {
  echo "usage: $(basename $0) TAG ARTIFACTORY_REPO"
  echo
  echo "Copy a release based on a tag from builder1"
}

args() {
  if [ $# -lt 2 ]; then
    usage
    exit 0
  fi
  H4CI_TAG=$1
  H4CI_PUBLISHER_REPO=$2
}

run_command() {
  if [ "${DRY_RUN}" != "false" ]; then
    echo "$*"
    return 0
  fi

  eval "$@"
}

artifactory_upload() {
  expression=$1

  echo "Checking if ${expression} exists..."
  binary_exists=$(JFROG_CLI_LOG_LEVEL=ERROR jfrog rt s "${H4CI_PUBLISHER_REPO}/${H4CI_TAG}/${expression}" | jq -r '.[].path' | wc -l)
  echo $binary_exists
  if [ "${binary_exists}" -eq "0" ]; then
    echo "Uploading to ${H4CI_PUBLISHER_REPO}/${H4CI_TAG}/"
    echo run_command "jfrog rt upload \"${expression}\" ${H4CI_PUBLISHER_REPO}/${H4CI_TAG}/"
  else
    echo "Binary already exists..."
  fi
}

# main
args "$@"

echo "==> Uploading mother rpm build"
artifactory_upload "${H4CI_TAG}/***REMOVED***_os_mother_rpm_k9-${H4CI_TAG}-1.el6.x86_64.rpm"
artifactory_upload "${H4CI_TAG}/***REMOVED***_os_adhoc_k9-${H4CI_TAG}-1.el6.x86_64.rpm"
artifactory_upload "${H4CI_TAG}/tet_updater-${H4CI_TAG}-1.el6.x86_64.rpm"
artifactory_upload "${H4CI_TAG}/***REMOVED***_os_UcsFirmware_k9-2.0.10e.rpm"

echo "==> Uploading qcow rpm"
artifactory_upload "${H4CI_TAG}/***REMOVED***_os_qcow_k9-${H4CI_TAG}-1.x86_64.rpm"

echo "==> Uploading qcow images"
artifactory_upload "${H4CI_TAG}/*${H4CI_TAG}.qcow2"

echo "==> Copying foundation rpms"
artifactory_upload "${H4CI_TAG}/*${H4CI_TAG}-1*.rpm"

echo "==> Copy ERSPAN OVA from union-local"
ERSPAN_OVA=$(JFROG_CLI_LOG_LEVEL=ERROR jfrog rt s '"union-local/erspan/erspan*"'  --props=version=latest | jq '.[].path')
echo $ERSPAN_OVA
echo jfrog rt cp ${ERSPAN_OVA} "${H4CI_PUBLISHER_REPO}/${H4CI_TAG}/"
