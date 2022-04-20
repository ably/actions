#!/bin/bash
set -eo pipefail

ARCH_ARR=("amd64" "arm64")

create_manifest() {
  image=$1
  tag=$2
  fail=0
  manifest_args=""

  for arch in "${ARCH_ARR[@]}"
  do
    arch_manifest="${REGISTRY}/${image}:${tag}-${arch}"
    echo "Finding ${arch_manifest}"
    docker manifest inspect "${arch_manifest}" > /dev/null || {
      echo "${arch_manifest} not available for ${arch}"
      return_code=1
      fail=1
    }
    manifest_args="${manifest_args} --amend ${arch_manifest}"
  done

  if [[ "${fail}" -eq "0" ]]; then
    manifest="${REGISTRY}/${image}:${tag}"
    echo "Pushing Manifest ${manifest} with ${manifest_args}"
    docker manifest create "${manifest}" ${manifest_args}
    docker manifest push --purge ${manifest}
  fi
}

main() {
  export return_code=0

  for image in ${IMAGES//,/ }; do
    if [[ "${GITHUB_REF_NAME}" == "main" ]]; then
      create_manifest "${image}" "main"
    fi

    create_manifest "${image}" "${TAG}"
    create_manifest "${image}" "${GITHUB_SHA}"
  done

  return ${return_code}
}

main "$@"
exit $?
