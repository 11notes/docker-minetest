# docker-minetest

Container running minetest server

## Volumes

/minetest/etc

Purpose: Minetest configuration files

/minetest/games

Purpose: Minetest games


## Run
```shell
docker run --name minetest \
    -v volume-etc:/minetest/etc \
    -v volume-games:/minetest/games \
    -d 11notes/minetest:[tag]
```

## Docker -u 1000:1000 (no root initiative)

As part to make containers more secure, this container will not run as root, but as uid:gid 1000:1000.

## Build with
* [Alpine Linux](https://alpinelinux.org/) - Alpine Linux
* [Minetest](https://www.minetest.net/) - Minetest

## Tips

* Don't bind to ports < 1024 (requires root), use NAT
* [Permanent Storge with NFS/CIFS/...](https://github.com/11notes/alpine-docker-netshare) - Module to store permanent container data via NFS/CIFS/...