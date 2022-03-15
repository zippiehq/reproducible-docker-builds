#!/bin/sh
mkdir -p /build
mkdir -p /build-result
mount -o ro -t squashfs /dev/vdb /build

cd /build/
while true; do
  if [ -e /var/run/docker.sock ]; then
  	break
  fi
  sleep 1
done
echo "Starting tail of console.." &> /dev/console

touch /mnt/result/docker-build.log
tail -f /mnt/result/docker-build.log > /dev/console &
TAILPID=$!

if [ -e /build/prebuild.sh ]; then
  echo "Running prebuild.." &> /dev/console
  ORIG=$PWD
  cd /build
  /build/prebuild.sh &> /dev/console
  cd $ORIG
fi

echo "Starting Docker build.." &> /dev/console
docker build --progress=tty -t build:1.0 . &> /mnt/result/docker-build.log
kill $TAILPID

ID=`docker images build:1.0 -q --no-trunc`
echo -n $ID > /mnt/result/docker-image.id
docker save $ID -o /mnt/result/docker-image.tar &> /dev/console && docker rm -v $ID
echo Docker result = $ID > /dev/console
poweroff
