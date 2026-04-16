FROM mcr.microsoft.com/dotnet/sdk:10.0-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        perl \
        cpanminus \
        git \
        procps \
        sudo \
    && rm -rf /var/lib/apt/lists/*

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}

ENV PATH="/home/vscode/.dotnet/tools:${PATH}"
RUN dotnet tool install -g aspire
