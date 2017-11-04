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
  binary_exists=$(JFROG_CLI_LOG_LEVEL=ERROR jfrog rt s "${H4CI_PUBLISHER_REPO}/${expression}" | jq -r '.[].path' | wc -l)
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

echo "==> Copy ERSPAN OVA"
erspan_ova=$(JFROG_CLI_LOG_LEVEL=ERROR jfrog rt s "union-local/erspan/erspan*" | jq -r '.[].path' | sort -nu | tail -1 )

if [ ! -z "$erspan_ova"]; then
  jfrog rt cp $erspan_ova "sandbox-local/erspan/erspan-${H4CI_TAG}.ova"
else
  echo "Cannot find last known good ERSPAN - $erspan_ova"
fi
