FROM debian:stable-20220328@sha256:bd2e4b7bdd9e439447e55eac1d485ec770be78fbaa679bee60252d8835877f1b AS kernel-base

ARG KERNEL_VERSION="5.5.19"
ARG KERNEL_URL="https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.gz"
ARG KERNEL_URL_SIG="https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.sign"

WORKDIR /build/kernel
RUN rm -rf /var/lib/apt /var/cache/apt
COPY --from=sha256:71db179277d5839e85dceb3cfbd41391e5b7c30311a6d2009b142eb8842f3d8a /var/lib/apt /var/lib/apt
COPY --from=sha256:71db179277d5839e85dceb3cfbd41391e5b7c30311a6d2009b142eb8842f3d8a /var/cache/apt /var/cache/apt

RUN apt-get install --no-download -y \
  bc \
  bison \
  build-essential \
  cpio \
  flex \
  libelf-dev \
  libssl-dev \
  wget \
  gnupg2 && rm -rf /var/lib/apt/lists/* && apt-get clean && rm -rf /var/lib/apt /var/cache/apt

RUN wget --progress=dot "$KERNEL_URL" && wget --progress=dot "$KERNEL_URL_SIG" && gunzip "linux-${KERNEL_VERSION}.tar.gz" && \
    gpg2 --locate-keys torvalds@kernel.org gregkh@kernel.org && \
    gpg2 --tofu-policy good 38DBBDC86092693E && \
    gpg2 --trust-model tofu --verify "linux-${KERNEL_VERSION}.tar.sign" && tar xf "linux-${KERNEL_VERSION}.tar" -C /build/kernel
FROM kernel-base as kernel-nokvm
ARG KERNEL_VERSION="5.5.19"

WORKDIR "/build/kernel/linux-${KERNEL_VERSION}"

COPY validator-kernel-q35-nokvm-config "/build/kernel/linux-${KERNEL_VERSION}/.config"

RUN KBUILD_BUILD_TIMESTAMP=0 KBUILD_BUILD_USER=root KBUILD_BUILD_HOST=localhost make olddefconfig && \ 
    KBUILD_BUILD_TIMESTAMP=0 KBUILD_BUILD_USER=root KBUILD_BUILD_HOST=localhost make -j$(nproc) bzImage && sha256sum arch/x86/boot/bzImage

FROM busybox
ARG KERNEL_VERSION="5.5.19"
COPY --from=kernel-nokvm "/build/kernel/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage" /builder/bzImage-nokvm-q35
COPY --from=kernel-nokvm "/build/kernel/linux-${KERNEL_VERSION}/.config" /builder/bzImage-nokvm-q35.config
RUN sha256sum /builder/bzImage-nokvm-q35 /builder/bzImage-nokvm-q35.config