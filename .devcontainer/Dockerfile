FROM mcr.microsoft.com/devcontainers/base:bookworm

USER vscode

RUN sudo apt-get update && sudo apt-get install -y pipx

RUN pipx install pre-commit && pipx ensurepath
