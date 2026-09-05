#!/bin/bash
set -euo pipefail

# mock user data
mkdir -p "${HOME}/Downloads" "${HOME}/Documents"
echo "this file must never be readable by the agent" >"${HOME}/Downloads/foo.txt"
echo "this file must never be readable by the agent" >"${HOME}/Documents/bar.txt"

# mock credentials
mkdir -p "${HOME}/.ssh" "${HOME}/.aws"
echo "MOCK-NOT-A-REAL-KEY" >"${HOME}/.ssh/id_ed25519"
echo "MOCK-NOT-A-REAL-CREDENTIAL" >"${HOME}/.aws/credentials"
chmod 600 "${HOME}/.ssh/id_ed25519" "${HOME}/.aws/credentials"

# git identity lives in the masked home and must be re-opened by allowRead.
git config --global user.name "Mock Host"
git config --global user.email "mock-host@example.invalid"
git config --global --add safe.directory "${PWD}"
