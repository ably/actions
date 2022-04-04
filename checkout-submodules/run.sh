#!/bin/bash
set -eo pipefail

SSH_KEY_NAME="id_$(date +%s)"
SSH_KEY_PATH="${HOME}/.ssh/${SSH_KEY_NAME}"
GIT_SSH_COMMAND="ssh -i ${SSH_KEY_PATH} -o IdentitiesOnly=yes" 
export GIT_SSH_COMMAND

main() {
  mkdir -p ~/.ssh
  echo "Adding private key: ${SSH_KEY_PATH}"
  test -f "${SSH_KEY_PATH}" || echo "${PRIVATE_SSH_KEY}" > "${SSH_KEY_PATH}"
  chmod 0400 "${SSH_KEY_PATH}"

  if ! test -f "${HOME}/.ssh/known_hosts" || ! grep -q github.com "${HOME}/.ssh/known_hosts"; then
    echo "Adding github.com identity (${KEY_TYPE})"
    ssh-keyscan -t "${KEY_TYPE}" github.com >> "${HOME}/.ssh/known_hosts"
  fi

  git submodule update --init --recursive
  echo "Submodules checked out"
}

cleanup() {
  test -f "${SSH_KEY_PATH}" && rm "${SSH_KEY_PATH}"
}

trap cleanup EXIT

main
