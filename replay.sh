#!/bin/sh
if [ x$2 = x ]; then
  BUILDDIR=$(mktemp -d /tmp/record.XXXXXXXXXX)
else
  BUILDDIR=$2
fi


rm -rf $BUILDDIR/replay-result
mkdir -p $BUILDDIR/replay-result

ORIG=$PWD
cd $BUILDDIR/replay-result
truncate -s 8G buildresult.img

cd $ORIG

mksquashfs $1 $BUILDDIR/replay-result/src.squashfs-replay -ef $BUILDDIR/replay-result/squashfs.exclude -reproducible -all-root -noI -noId -noD -noF -noX -mkfs-time 0 -all-time 0

if cmp -s $BUILDDIR/replay/src.squashfs $BUILDDIR/replay-result/src.squashfs-replay; then
  echo "Source squashfs matches"
else
  echo "Source squashfs mismatch, exiting"
  exit 1
fi
rm $BUILDDIR/replay-result/src.squashfs-replay

touch $BUILDDIR/replay-result/output.serial
tail -f $BUILDDIR/replay-result/output.serial &
TAILPID=$!
time qemu-system-x86_64 \
   -display none  \
   -no-user-config \
   -nodefaults -no-reboot \
   -device virtio-blk-pci,drive=root-blkreplay \
   -device virtio-blk-pci,drive=src-blkreplay \
   -device virtio-blk-pci,drive=dest-blkreplay \
   -m 8192m -cpu qemu64 \
   -icount shift=auto,rr=replay,rrfile=$BUILDDIR/replay/execution.trace \
   -accel accel=tcg,tb-size=4294967200 \
   -device virtio-serial-pci,id=virtio-serial0 \
   -chardev file,path=$BUILDDIR/replay-result/output.serial,id=serial \
   -device virtconsole,chardev=serial,id=console0 \
   -append "earlyprintk=hvc0 console=hvc0 reboot=t root=/dev/vda ro elevator=noop norandmaps mitigations=off init=/sbin/overlay-init" \
   -rtc clock=host -kernel $BUILDDIR/replay/bzImage-nokvm-q35 \
   -drive "driver=raw,if=none,file=$BUILDDIR/replay/builder.squashfs,readonly=on,id=root-direct" -drive "driver=blkreplay,if=none,image=root-direct,id=root-blkreplay,readonly=on" \
   -drive "driver=raw,if=none,file=$BUILDDIR/replay/src.squashfs,readonly=on,id=src-direct" -drive "driver=blkreplay,if=none,image=src-direct,readonly=on,id=src-blkreplay" \
   -drive "driver=raw,if=none,file=$BUILDDIR/replay-result/buildresult.img,cache=off,id=dest-direct" -drive "driver=blkreplay,if=none,image=dest-direct,id=dest-blkreplay" \
   -netdev user,id=net1 -device rtl8139,netdev=net1 -object filter-replay,id=replay,netdev=net1

kill $TAILPID
e2cp $BUILDDIR/replay-result/buildresult.img:/result/docker-image.id $BUILDDIR/replay-result/docker-image.id
e2cp $BUILDDIR/replay-result/buildresult.img:/result/docker-build.log $BUILDDIR/replay-result/docker-build.log
e2cp $BUILDDIR/replay-result/buildresult.img:/result/docker-image.tar $BUILDDIR/replay-result/docker-image.tar

ORIG=$PWD
cd $BUILDDIR/replay-result
rm $BUILDDIR/replay-result/buildresult.img
sha256sum /builder/builder.squashfs /builder/bzImage-nokvm-q35 * > $BUILDDIR/MANIFEST.sha256
cd $ORIG
mv $BUILDDIR/MANIFEST.sha256 $BUILDDIR/replay-result/MANIFEST.sha256
cat $BUILDDIR/replay-result/MANIFEST.sha256
echo
cat $BUILDDIR/replay-result/docker-image.id
echo
