FROM debian:stable-20220328@sha256:bd2e4b7bdd9e439447e55eac1d485ec770be78fbaa679bee60252d8835877f1b as debian-base
RUN apt-get update && apt-get -d install -y \
  bc \
  bison \
  build-essential \
  cpio \
  flex \
  libelf-dev \
  libssl-dev \
  wget

FROM alpine:3.15.3@sha256:1e014f84205d569a5cc3be4e108ca614055f7e21d11928946113ab3f36054801 AS buildstep
RUN mkdir /etc/apk/cache && cd /etc/apk/cache && apk update && apk fetch -R docker dhclient openrc iptables qemu-system-x86_64 qemu-accel-tcg-x86_64 curl e2fsprogs squashfs-tools qemu-img e2tools e2fsprogs-extra

FROM scratch
COPY --from=debian-base /var/lib/apt /var/lib/apt
COPY --from=debian-base /var/cache/apt /var/cache/apt
COPY --from=buildstep /etc/apk/cache /etc/apk/cache
