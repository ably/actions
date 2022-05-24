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
      echo "ERROR: ${arch_manifest} not available for ${arch}"
      return_code=1
      fail=1
    }
    manifest_args="${manifest_args} --amend ${arch_manifest}"
  done

  if [[ "${fail}" -eq "0" ]]; then
    manifest="${REGISTRY}/${image}:${tag}"
    echo "Pushing Manifest ${manifest} with ${manifest_args}"
    docker manifest create "${manifest}" ${manifest_args}

    detected_archs=$(docker manifest inspect "${manifest}" | jq -r '.manifests[].platform.architecture')
    for arch in "${ARCH_ARR[@]}"; do
      if ! grep -q "${arch}" <<< "${detected_archs}"; then
        echo "ERROR: Architecture ${arch} not detected for manifest ${manifest}"
        return_code=1
        fail=1
        return
      fi
    done

    docker manifest push --purge ${manifest}
  fi
}

main() {
  export return_code=0

  echo "### New images available" >> "${GITHUB_STEP_SUMMARY}"

  for image in ${IMAGES//,/ }; do
    if [[ "${GITHUB_REF_NAME}" == "main" ]]; then
      create_manifest "${image}" "main"
    fi

    create_manifest "${image}" "${TAG}"
    create_manifest "${image}" "${GITHUB_SHA}"

    echo "${image}:${TAG}" >> "${GITHUB_STEP_SUMMARY}"
  done

  return ${return_code}
}

main "$@"
exit $?
