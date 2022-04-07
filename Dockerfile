FROM alpine:3.15.3@sha256:1e014f84205d569a5cc3be4e108ca614055f7e21d11928946113ab3f36054801 AS buildstep
COPY --from=zippiehq/reproducible-docker-builds-cache:1.0@sha256:1935663b466c727a5f6420b3c74509123904a14a806be61c8ae48493305ae06c /etc/apk/cache /etc/apk/cache
RUN apk add --no-network /etc/apk/cache/*.apk && rm -rf /etc/apk/cache && rm -rf /lib/apk/db/*
RUN ln -s /sbin/mksquashfs /sbin/sqfstar
RUN mkdir -p /var/lib/docker /etc/docker /opt/containerd /mnt
RUN sed -i s/\#rc_cgroup_mode/rc_cgroup_mode/g /etc/rc.conf
RUN rc-update add devfs sysinit && rc-update add procfs sysinit && rc-update add sysfs sysinit && rc-update add cgroups sysinit && rc-update add networking sysinit && rc-update add docker boot && rc-update add local default
RUN echo DOCKERD_BINARY=/usr/bin/dockerd-logger >> /etc/conf.d/docker
COPY build.sh /etc/local.d/build.start
COPY fstab /etc/fstab
COPY dockerd-logger /usr/bin/dockerd-logger
COPY record.sh /usr/bin/record.sh
COPY replay.sh /usr/bin/replay.sh
COPY interfaces /etc/network/interfaces
COPY overlay-init /sbin/overlay-init

FROM buildstep AS imgstep
COPY --from=buildstep / /image
RUN mksquashfs /image /image.squashfs -reproducible -all-root -noI -noId -noD -noF -noX -mkfs-time 0 -all-time 0 && sha256sum /image.squashfs

FROM buildstep
COPY bzImage-nokvm-q35 /builder/bzImage-nokvm-q35
COPY --from=imgstep /image.squashfs /builder/builder.squashfs
RUN sha256sum /builder/bzImage-nokvm-q35 /builder/builder.squashfs
