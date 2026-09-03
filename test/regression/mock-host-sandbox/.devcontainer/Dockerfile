FROM mcr.microsoft.com/devcontainers/base:bookworm

USER vscode

# bubblewrap and socat required by Claude Code sandbox
RUN sudo apt-get update && sudo apt-get install -y \
  bubblewrap \
  socat \
  curl

RUN curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
