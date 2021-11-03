# :: Build
	FROM alpine:latest as build
	ENV minetestVersion=5.4.1

    RUN set -ex; \
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories; \
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories; \
        apk add --update --no-cache \
            git \
			bzip2-dev \
			cmake \
			curl-dev \
			doxygen \
			g++ \
			gcc \
			git \
			gmp-dev \
			hiredis-dev \
            ncurses-dev \
			icu-dev \
			libjpeg-turbo-dev \
			libogg-dev \
			libpng-dev \
			libressl-dev \
			libtool \
			libvorbis-dev \
			luajit-dev \
			make \
			mesa-dev \
			openal-soft-dev \
			python3-dev \
            jsoncpp-dev \
            irrlicht-dev \
            libspatialindex-dev \
			zstd-dev \
			sqlite-dev; \
        git clone -b ${minetestVersion} --single-branch --depth 1 https://github.com/minetest/minetest.git; \
        cd /minetest; \
        git clone -b ${minetestVersion} --single-branch --depth 1 https://github.com/minetest/minetest_game.git games/minetest_game;

	WORKDIR /minetest

    RUN set -ex; \
        cmake . \
            -DRUN_IN_PLACE=1 \
            -DBUILD_CLIENT=0 \
            -DBUILD_SERVER=1 \
            -DRUN_IN_PLACE=1 \
            -DENABLE_SYSTEM_JSONCPP=1 \
            -DENABLE_FREETYPE=0 \
            -DENABLE_GETTEXT=0 \
            -DENABLE_LEVELDB=0 \
            -DENABLE_POSTGRESQL=0 \
            -DENABLE_REDIS=1 \
            -DENABLE_CURL=1 \
            -DENABLE_LUAJIT=1 \
            -DENABLE_SPATIAL=1; \
        make -j $(nproc); \
        mkdir -p /build; \
        cp -R bin /build; \
        cp -R games /build; \
        cp -R builtin /build;

# :: Header
	FROM alpine:3.14
	COPY --from=build /build/ /minetest

# :: Run
	USER root

	# :: prepare
		RUN set -ex; \
			echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories; \
			echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories; \
			apk add --update --no-cache \
				curl \
				gmp \
				libgcc \
				libintl \
				libstdc++ \
				luajit \
				lua-socket \
				sqlite \
				sqlite-libs \
				jsoncpp \
				hiredis \
				libspatialindex \
				zstd \
				shadow;

		RUN set -ex; \
			mkdir -p /minetest/worlds; \
			mkdir -p /minetest/log; \
			addgroup --gid 1000 -S minetest; \
			adduser --uid 1000 -D -S -h /minetest -s /sbin/nologin -G minetest minetest;

    # :: copy root filesystem changes
        COPY ./rootfs / 

    # :: docker -u 1000:1000 (no root initiative)
        RUN set -ex; \
            chown -R minetest:minetest /minetest

# :: Volumes
	VOLUME ["/minetest/etc", "/minetest/games", "/minetest/worlds"]

# :: Start
	USER minetest
	CMD ["/minetest/bin/minetestserver", "--config", "/minetest/etc/default.conf", "--logfile", "/minetest/log/default.log"]