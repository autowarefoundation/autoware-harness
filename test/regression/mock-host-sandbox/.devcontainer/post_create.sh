#!/bin/bash
set -euo pipefail

# mock user data
mkdir -p "${HOME}/Downloads" "${HOME}/Documents"
echo "this file must never be readable by the agent" >"${HOME}/Downloads/foo.txt"
echo "this file must never be readable by the agent" >"${HOME}/Documents/bar.txt"

# Mock credentials. `~/.ssh` is enumerated in `permissions.deny` and `~/.aws`
# deliberately is not, so the verification can compare the two.
mkdir -p "${HOME}/.ssh" "${HOME}/.aws"
echo "MOCK-NOT-A-REAL-KEY" >"${HOME}/.ssh/id_ed25519"
echo "MOCK-NOT-A-REAL-CREDENTIAL" >"${HOME}/.aws/credentials"
chmod 600 "${HOME}/.ssh/id_ed25519" "${HOME}/.aws/credentials"

# git identity lives in the masked home and must be re-opened by allowRead.
git config --global user.name "Mock Host"
git config --global user.email "mock-host@example.invalid"
git config --global --add safe.directory "${PWD}"

# A credential inside a directory the toolchain rules deliberately re-open:
# `~/.config/git` appears in both `permissions.allow` and sandbox `allowRead`.
# Enumeration fails here in the opposite direction -- the allow-rule is broad.
mkdir -p "${HOME}/.config/git"
echo "https://mock-user:MOCK-NOT-A-REAL-TOKEN@github.com" >"${HOME}/.config/git/credentials"
chmod 600 "${HOME}/.config/git/credentials"
