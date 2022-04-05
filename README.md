
NOTE: This README.md is not part of the replayable source set

# Verifying the builds

0. `IPFS_GATEWAY=https://ipfs.io`
1. `mkdir -p verify-reproducible-docker-builds`
2. `cd verify-reproducible-docker-builds`

3. `wget -O reproducible-docker-builds-1.0-07c29267e29a37940306936461b5c87052abb5b5b03f213f034cd538f84caf05.tar.bz2 $IPFS_GATEWAY/ipfs/bafybeihsrealckwexpxqqymxorxs22rrvn5xah2bwr3ek5zpejru43h43i` # 987.68M size

4. `wget -O reproducible-docker-builds-cache-1.0-35b5d54c8a901db6bd02893c12dcaf97d02494e518c1081326e2241fe4820721.tar.bz2 $IPFS_GATEWAY/ipfs/bafybeiggrhijidd3bkjfv2jwl3e7fpt5h4fkteykjgqao6d3nbpffdtwte` # 389.90M size

5. `tar --sparse -xf reproducible-docker-builds-1.0-07c29267e29a37940306936461b5c87052abb5b5b03f213f034cd538f84caf05.tar.bz2`
6. `tar --sparse -xf reproducible-docker-builds-cache-1.0-35b5d54c8a901db6bd02893c12dcaf97d02494e518c1081326e2241fe4820721.tar.bz2`

6.1: Notice there is no replay-result/ in `reproducible-docker-builds-cache-1.0-35b5d54c8a901db6bd02893c12dcaf97d02494e518c1081326e2241fe4820721/` and `reproducible-docker-builds-1.0-07c29267e29a37940306936461b5c87052abb5b5b03f213f034cd538f84caf05`

7. `umask 0022; git clone https://github.com/zippiehq/reproducible-docker-builds` # this umask is important to get same source file permissions
8. `git checkout v1.0` # or specific git commit
9. `cd reproducible-docker-builds`
10. `docker pull zippiehq/reproducible-docker-builds:1.0`
11. `docker pull zippiehq/reproducible-docker-builds-cache:1.0`
12. `docker image inspect zippiehq/reproducible-docker-builds:1.0`
13. Verify that the inspect command shows the following Id for the zippiehq/reproducible-docker-builds:1.0 image:
      `  "Id": "sha256:07c29267e29a37940306936461b5c87052abb5b5b03f213f034cd538f84caf05", `

14. docker image inspect zippiehq/reproducible-docker-builds-cache:1.0

15. Verify that the inspect command shows the following Id for the zippiehq/reproducible-docker-builds-cache:1.0 image:
      `  "Id": "sha256:35b5d54c8a901db6bd02893c12dcaf97d02494e518c1081326e2241fe4820721", `


This will take about 8 minutes:

16. `docker run -it -v $PWD/cache:/src -v $(realpath ../reproducible-docker-builds-cache-1.0-35b5d54c8a901db6bd02893c12dcaf97d02494e518c1081326e2241fe4820721):/build-out zippiehq/reproducible-docker-builds:1.0 /bin/sh -c 'SQUASHFS_EXCLUDE=$(printf ".git\nREADME.md\n") /usr/bin/replay.sh /src /build-out'`

The following will take 4-5 hours, so consider running it in a 'screen' or
similar:

17. `docker run -it -v $PWD:/src -v $(realpath ../reproducible-docker-builds-1.0-07c29267e29a37940306936461b5c87052abb5b5b03f213f034cd538f84caf05):/build-out zippiehq/reproducible-docker-builds:1.0 /bin/sh -c 'SQUASHFS_EXCLUDE=$(printf ".git\nREADME.md\n") /usr/bin/replay.sh /src /build-out'`

Then we verify the resulting docker builds yield same docker ID as earlier:

18. `docker load -i ../reproducible-docker-builds-cache-1.0-35b5d54c8a901db6bd02893c12dcaf97d02494e518c1081326e2241fe4820721/replay-result/docker-image.tar`

Should say:

`Loaded image ID: sha256:35b5d54c8a901db6bd02893c12dcaf97d02494e518c1081326e2241fe4820721`

19. `docker load -i ../reproducible-docker-builds-1.0-07c29267e29a37940306936461b5c87052abb5b5b03f213f034cd538f84caf05/replay-result/docker-image.tar`

Should say:

`Loaded image ID: sha256:07c29267e29a37940306936461b5c87052abb5b5b03f213f034cd538f84caf05`
