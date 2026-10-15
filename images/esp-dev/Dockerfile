# syntax=docker/dockerfile:1.7

FROM lscr.io/linuxserver/webtop:ubuntu-xfce@sha256:51cc1e6fa00ffbd41c05b61bb3b36f30dd68e35206501407fe6980ffd1d56982

ARG TARGETARCH

# renovate: datasource=github-releases depName=microsoft/vscode
ARG VSCODE_VERSION=1.142.0
# renovate: datasource=github-releases depName=espressif/esp-idf
ARG ESP_IDF_VERSION=v6.1
ARG ESP_IDF_TARGETS=esp32,esp32s2,esp32s3,esp32c2,esp32c3,esp32c6,esp32h2
# renovate: datasource=github-releases depName=arduino/arduino-cli
ARG ARDUINO_CLI_VERSION=v1.5.1
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=v2.102.0
# renovate: datasource=node-version depName=node
ARG NODE_VERSION=v24.22.0
# renovate: datasource=pypi depName=esphome
ARG ESPHOME_VERSION=2026.9.1
# renovate: datasource=pypi depName=platformio
ARG PLATFORMIO_VERSION=6.2.0
# renovate: datasource=pypi depName=esptool
ARG ESPTOOL_VERSION=5.6.0
# renovate: datasource=pypi depName=uv
ARG UV_VERSION=0.13.1
# renovate: datasource=npm depName=@openai/codex
ARG CODEX_VERSION=0.162.1
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=v4.54.1

ENV DEBIAN_FRONTEND=noninteractive \
    IDF_PATH=/opt/esp/idf \
    IDF_TOOLS_PATH=/config/.espressif \
    ESP_IDF_VERSION=${ESP_IDF_VERSION} \
    ESP_IDF_TARGETS=${ESP_IDF_TARGETS} \
    PATH=/opt/esp-tools/bin:/opt/esphome/bin:/opt/platformio/bin:/usr/local/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash-completion \
      bat \
      bison \
      build-essential \
      ca-certificates \
      ccache \
      clang \
      clang-format \
      clang-tidy \
      cmake \
      curl \
      dfu-util \
      dnsutils \
      fd-find \
      flex \
      gdb \
      git \
      gperf \
      iputils-ping \
      intel-media-va-driver \
      jq \
      libffi-dev \
      libgl1-mesa-dri \
      libssl-dev \
      libusb-1.0-0 \
      libusb-1.0-0-dev \
      make \
      mesa-utils \
      mosquitto-clients \
      netcat-openbsd \
      ninja-build \
      openssh-client \
      picocom \
      python3 \
      python3-pip \
      python3-venv \
      ripgrep \
      rsync \
      shellcheck \
      shfmt \
      socat \
      unzip \
      usbutils \
      vainfo \
      wget \
      xz-utils \
      zip \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) vscode_arch=x64; archive_arch=x64 ;; \
      arm64) vscode_arch=arm64; archive_arch=arm64 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://update.code.visualstudio.com/${VSCODE_VERSION}/linux-deb-${vscode_arch}/stable" -o /tmp/code.deb; \
    apt-get update; \
    apt-get install -y --no-install-recommends /tmp/code.deb; \
    rm -rf /tmp/code.deb /var/lib/apt/lists/*; \
    node_archive="node-${NODE_VERSION}-linux-${archive_arch}.tar.xz"; \
    curl -fsSLO "https://nodejs.org/dist/${NODE_VERSION}/${node_archive}"; \
    curl -fsSLO "https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt"; \
    grep " ${node_archive}$" SHASUMS256.txt | sha256sum -c -; \
    tar -xJf "${node_archive}" -C /usr/local --strip-components=1; \
    rm -f "${node_archive}" SHASUMS256.txt; \
    npm install --global "@openai/codex@${CODEX_VERSION}"; \
    corepack enable; \
    ln -s /usr/bin/batcat /usr/local/bin/bat; \
    ln -s /usr/bin/fdfind /usr/local/bin/fd

RUN set -eux; \
    version="${GH_VERSION#v}"; \
    case "${TARGETARCH}" in amd64) arch=amd64 ;; arm64) arch=arm64 ;; esac; \
    archive="gh_${version}_linux_${arch}.tar.gz"; \
    curl -fsSLO "https://github.com/cli/cli/releases/download/${GH_VERSION}/${archive}"; \
    curl -fsSL "https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${version}_checksums.txt" -o checksums.txt; \
    grep " ${archive}$" checksums.txt | sha256sum -c -; \
    tar -xzf "${archive}"; \
    install -m 0755 "gh_${version}_linux_${arch}/bin/gh" /usr/local/bin/gh; \
    rm -rf "${archive}" checksums.txt "gh_${version}_linux_${arch}"

RUN set -eux; \
    version="${ARDUINO_CLI_VERSION#v}"; \
    case "${TARGETARCH}" in amd64) arch=Linux_64bit ;; arm64) arch=Linux_ARM64 ;; esac; \
    archive="arduino-cli_${version}_${arch}.tar.gz"; \
    curl -fsSLO "https://github.com/arduino/arduino-cli/releases/download/${ARDUINO_CLI_VERSION}/${archive}"; \
    curl -fsSL "https://github.com/arduino/arduino-cli/releases/download/${ARDUINO_CLI_VERSION}/${version}-checksums.txt" -o checksums.txt; \
    grep " ${archive}$" checksums.txt | sha256sum -c -; \
    tar -xzf "${archive}" arduino-cli; \
    install -m 0755 arduino-cli /usr/local/bin/arduino-cli; \
    rm -f arduino-cli "${archive}" checksums.txt

RUN set -eux; \
    case "${TARGETARCH}" in amd64) arch=amd64 ;; arm64) arch=arm64 ;; esac; \
    binary="yq_linux_${arch}"; \
    curl -fsSLO "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${binary}"; \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/checksums" -o checksums.txt; \
    awk -v name="${binary}" '$1 == name { print $19 "  " $1 }' checksums.txt | sha256sum -c -; \
    install -m 0755 "${binary}" /usr/local/bin/yq; \
    rm -f "${binary}" checksums.txt

RUN python3 -m venv /opt/esp-tools \
    && /opt/esp-tools/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
    && /opt/esp-tools/bin/pip install --no-cache-dir \
      "esptool==${ESPTOOL_VERSION}" \
      pre-commit \
      "uv==${UV_VERSION}" \
    && python3 -m venv /opt/esphome \
    && /opt/esphome/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
    && /opt/esphome/bin/pip install --no-cache-dir "esphome==${ESPHOME_VERSION}" \
    && python3 -m venv /opt/platformio \
    && /opt/platformio/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
    && /opt/platformio/bin/pip install --no-cache-dir "platformio==${PLATFORMIO_VERSION}"

RUN git clone --branch "${ESP_IDF_VERSION}" --depth 1 --recursive \
      https://github.com/espressif/esp-idf.git "${IDF_PATH}" \
    && rm -rf "${IDF_PATH}/.git" \
    && printf '%s\n' \
      "export IDF_PATH=${IDF_PATH}" \
      "export IDF_TOOLS_PATH=${IDF_TOOLS_PATH}" \
      '[ -f "${IDF_PATH}/export.sh" ] && . "${IDF_PATH}/export.sh" >/dev/null 2>&1' \
      > /etc/profile.d/esp-idf.sh

COPY extensions.txt /tmp/extensions.txt
RUN install -d /opt/vscode-extensions /tmp/vscode-data \
    && while IFS= read -r extension; do \
         code --no-sandbox --user-data-dir /tmp/vscode-data \
           --extensions-dir /opt/vscode-extensions \
           --install-extension "${extension}" --force; \
       done < /tmp/extensions.txt \
    && rm -rf /tmp/extensions.txt /tmp/vscode-data

COPY defaults/ /opt/workspace-defaults/
COPY root/ /

RUN chmod 0755 /custom-cont-init.d/20-coder-workspace \
      /usr/local/bin/bootstrap-esp-idf /usr/local/bin/idf.py \
    && chmod -R a+rX /opt/esp-tools /opt/esphome /opt/platformio \
      /opt/vscode-extensions /opt/workspace-defaults

ENV DEBIAN_FRONTEND=

LABEL org.opencontainers.image.source="https://github.com/ExhaleSthlm/coder-images-and-templates" \
      org.opencontainers.image.description="ESP32 development desktop for Coder with XFCE, Selkies and VS Code"
