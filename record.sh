#!/bin/sh
if [ x$2 = x ]; then
  BUILDDIR=$(mktemp -d /tmp/record.XXXXXXXXXX)
else
  rm -rf $2/reproducible-build-output
  mkdir -p $2/reproducible-build-output
  BUILDDIR=$2/reproducible-build-output
fi

mkdir -p $BUILDDIR/replay
mkdir -p $BUILDDIR/result

ORIG=$PWD
cd $BUILDDIR/replay

sha256sum /builder/builder.squashfs /builder/bzImage-nokvm-q35 > BASE.sha256sum
cp -v /builder/builder.squashfs /builder/bzImage-nokvm-q35 .

if [ x$BUILDRESULT_SIZE = x ]; then
   BUILDRESULT_SIZE=8G
fi

if [ x$RAM_SIZE = x ]; then
   RAM_SIZE=8192m
fi


truncate -s $BUILDRESULT_SIZE buildresult.img

cd ../result
truncate -s $BUILDRESULT_SIZE buildresult.img

cd $ORIG

# Reads a sources tar from stdin
sqfstar -reproducible -all-root -noI -noId -noD -noF -noX -mkfs-time 0 -all-time 0 $BUILDDIR/replay/src.squashfs

touch $BUILDDIR/result/output.serial
tail -f $BUILDDIR/result/output.serial &
TAILPID=$!
time qemu-system-x86_64 \
   -display none  \
   -no-user-config \
   -nodefaults -no-reboot \
   -device virtio-blk-pci,drive=root-blkreplay \
   -device virtio-blk-pci,drive=src-blkreplay \
   -device virtio-blk-pci,drive=dest-blkreplay \
   -m $RAM_SIZE -cpu qemu64 \
   -icount shift=auto,rr=record,rrfile=$BUILDDIR/replay/execution.trace \
   -accel accel=tcg,tb-size=4294967200 \
   -device virtio-serial-pci,id=virtio-serial0 \
   -chardev file,path=$BUILDDIR/result/output.serial,id=serial \
   -device virtconsole,chardev=serial,id=console0 \
   -append "earlyprintk=hvc0 console=hvc0 reboot=t root=/dev/vda ro elevator=noop norandmaps mitigations=off init=/sbin/overlay-init" \
   -rtc clock=host -kernel $BUILDDIR/replay/bzImage-nokvm-q35 \
   -drive "driver=raw,if=none,file=$BUILDDIR/replay/builder.squashfs,readonly=on,id=root-direct" -drive "driver=blkreplay,if=none,image=root-direct,id=root-blkreplay,readonly=on" \
   -drive "driver=raw,if=none,file=$BUILDDIR/replay/src.squashfs,readonly=on,id=src-direct" -drive "driver=blkreplay,if=none,image=src-direct,readonly=on,id=src-blkreplay" \
   -drive "driver=raw,if=none,file=$BUILDDIR/result/buildresult.img,cache=off,id=dest-direct" -drive "driver=blkreplay,if=none,image=dest-direct,id=dest-blkreplay" \
   -netdev user,id=net1 -device rtl8139,netdev=net1 -object filter-replay,id=replay,netdev=net1

kill $TAILPID

e2cp $BUILDDIR/result/buildresult.img:/result/docker-image.id $BUILDDIR/result/docker-image.id
e2cp $BUILDDIR/result/buildresult.img:/result/docker-build.log $BUILDDIR/result/docker-build.log
e2cp $BUILDDIR/result/buildresult.img:/result/docker-image.tar $BUILDDIR/result/docker-image.tar
ORIG=$PWD
cd $BUILDDIR/result
rm buildresult.img

sha256sum /builder/builder.squashfs /builder/bzImage-nokvm-q35 * > $BUILDDIR/MANIFEST.sha256
cd $ORIG
mv $BUILDDIR/MANIFEST.sha256 $BUILDDIR/result/MANIFEST.sha256

cat $BUILDDIR/result/MANIFEST.sha256
echo
cat $BUILDDIR/result/docker-image.id
echo
