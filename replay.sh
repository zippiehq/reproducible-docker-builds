#!/bin/sh
BUILDDIR=$(mktemp -d /tmp/record.XXXXXXXXXX)

if [ x$BUILDRESULT_SIZE = x ]; then
   BUILDRESULT_SIZE=8G
fi

if [ x$RAM_SIZE = x ]; then
   RAM_SIZE=8192m
fi
rm -rf $BUILDDIR/replay-result
mkdir -p $BUILDDIR/replay-result

ORIG=$PWD
cd $BUILDDIR/replay-result
truncate -s $BUILDRESULT_SIZE buildresult.img

cd $ORIG

sqfstar -reproducible -all-root -noI -noId -noD -noF -noX -mkfs-time 0 -all-time 0 $BUILDDIR/replay-result/src.squashfs-replay

if cmp -s $1/reproducible-build-output/replay/src.squashfs $BUILDDIR/replay-result/src.squashfs-replay; then
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
   -icount shift=auto,rr=replay,rrfile=$1/reproducible-build-output/replay/execution.trace \
   -accel accel=tcg,tb-size=4294967200 \
   -device virtio-serial-pci,id=virtio-serial0 \
   -chardev file,path=$BUILDDIR/replay-result/output.serial,id=serial \
   -device virtconsole,chardev=serial,id=console0 \
   -append "earlyprintk=hvc0 console=hvc0 reboot=t root=/dev/vda ro elevator=noop norandmaps mitigations=off init=/sbin/overlay-init" \
   -rtc clock=host -kernel $1/reproducible-build-output/replay/bzImage-nokvm-q35 \
   -drive "driver=raw,if=none,file=$1/reproducible-build-output/replay/builder.squashfs,readonly=on,id=root-direct" -drive "driver=blkreplay,if=none,image=root-direct,id=root-blkreplay,readonly=on" \
   -drive "driver=raw,if=none,file=$1/reproducible-build-output/replay/src.squashfs,readonly=on,id=src-direct" -drive "driver=blkreplay,if=none,image=src-direct,readonly=on,id=src-blkreplay" \
   -drive "driver=raw,if=none,file=$BUILDDIR/replay-result/buildresult.img,cache=off,id=dest-direct" -drive "driver=blkreplay,if=none,image=dest-direct,id=dest-blkreplay" \
   -netdev user,id=net1 -device rtl8139,netdev=net1 -object filter-replay,id=replay,netdev=net1

kill $TAILPID
mkdir -p $1/reproducible-build-output/replay-result
e2cp $BUILDDIR/replay-result/buildresult.img:/result/docker-image.id $1/reproducible-build-output/replay-result/docker-image.id
e2cp $BUILDDIR/replay-result/buildresult.img:/result/docker-build.log $1/reproducible-build-output/replay-result/docker-build.log
e2cp $BUILDDIR/replay-result/buildresult.img:/result/docker-image.tar $1/reproducible-build-output/replay-result/docker-image.tar

rm $BUILDDIR/replay-result/buildresult.img
cp $BUILDDIR/replay-result/* $1/reproducible-build-output/replay-result/

ORIG=$PWD
cd $1/reproducible-build-output/replay-result
sha256sum /builder/builder.squashfs /builder/bzImage-nokvm-q35 * > $BUILDDIR/MANIFEST.sha256
mv $BUILDDIR/MANIFEST.sha256 .
cd $ORIG

cat $1/reproducible-build-output/replay-result/MANIFEST.sha256
echo
cat $1/reproducible-build-output/replay-result/docker-image.id
echo
