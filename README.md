
NOTE: This README.md is not part of the replayable source set

# Getting the software

1. `docker pull zippiehq/reproducible-docker-builds:1.1`

2. `docker pull zippiehq/reproducible-docker-builds-cache:1.1`

# Verifying the builds

## Getting the source tree
1. `git clone https://github.com/zippiehq/reproducible-docker-builds`
2. `git checkout v1.1` # or specific git commit 2da43f3411b3792b6f401fa6d84e5794d71ddaac
3. `cd reproducible-docker-builds`

## Verifying the kernel build

The kernel in use can be reproduced:

4. `docker build -t zippiehq/reproducible-kernel-builds-kernel:1.1 kernel; ID=$(docker create zippiehq/reproducible-kernel-builds-kernel:1.1)`; docker cp $ID:/builder/bzImage-nokvm-q35 bzImage-nokvm-q35.selfbuilt ; docker rm $ID`

5. Confirm this: `sha256sum bzImage-nokvm-q35 bzImage-nokvm-q35.selfbuilt`, gives the following output (that the files match)

`5d4778ba0cdc1284d2f7bae84751fbc2be8c658d3d32b301d4be5a8e16f2cd94 bzImage-nokvm-q35
5d4778ba0cdc1284d2f7bae84751fbc2be8c658d3d32b301d4be5a8e16f2cd94 bzImage-nokvm-q35.selfbuilt`

6. `rm -f bzImage-nokvm-q35.selfbuilt` # we don't need it anymore

7. `IPFS_GATEWAY=https://ipfs.io`   # or select your own

## Checking the metadata of the published containers

8. `docker pull zippiehq/reproducible-docker-builds:1.1`

9. `docker pull zippiehq/reproducible-docker-builds-cache:1.1`

10. `docker image inspect zippiehq/reproducible-docker-builds:1.1`
11. Verify that the inspect command shows the following Id for the zippiehq/reproducible-docker-builds:1.1 image:
     `         "Id": "sha256:730fbb363bf5329c8fa2dbc50a25474aeffd01cca74f275494d2717c5e4c99d1", `

12. docker image inspect zippiehq/reproducible-docker-builds-cache:1.1

13. Verify that the inspect command shows the following Id for the zippiehq/reproducible-docker-builds-cache:1.1 image:
     ` "Id": "sha256:a84a4fc65ceaa9b5b8b2cd287cfa07d004fb409f1016e2c1e2d7ad3af9e8fe0b", `

## Getting the reproducible build replay material

14. `wget -O reproducible-docker-build-1.1.tar.bz2 $IPFS_GATEWAY/ipfs/bafybeihqwv3hfessgcanexrr7szixeuo3vl7pt3l32jpsz5ybiwdtebnwa` # (819.12mb size)

15. `tar --sparse -xf reproducible-docker-build-1.1.tar.bz2`

16. Notice there is no replay-result in cache/reproducible-build-result/ and reproducible-build-result/


## Replaying the build process for the cache container, This will take about 8 minutes:

17. `cd cache && git -c "tar.umask=0002" archive --format=tar  HEAD | docker run -v $PWD:/out -i zippiehq/reproducible-docker-builds:1.1 /usr/bin/replay.sh /out && cd ..`

## Replaying the build process for the builds container, this will take about 18 minutes

18. git -c "tar.umask=0022" archive --format=tar  HEAD | docker run -v $PWD:/out -i zippiehq/reproducible-docker-builds:1.1 /usr/bin/replay.sh /out

## Then we verify the resulting builds yield same docker ID as earlier:

19. `docker load -i reproducible-build-output/replay-result/docker-image.tar`

Which should show:

`Loaded image ID: sha256:730fbb363bf5329c8fa2dbc50a25474aeffd01cca74f275494d2717c5e4c99d1`

Which matches the above ID for zippiehq/reproducible-docker-builds:1.1

20. `docker load -i cache/reproducible-build-output/replay-result/docker-image.tar`

Which should show:

`Loaded image ID: sha256:a84a4fc65ceaa9b5b8b2cd287cfa07d004fb409f1016e2c1e2d7ad3af9e8fe0b`


