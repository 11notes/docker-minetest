# :: Build
	FROM alpine:latest as build
	ENV minetestVersion=5.5.0

    RUN set -ex; \
        echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories; \
        apk add --update --no-cache \
			build-base \
            git \
			bzip2-dev \
			cmake \
			freetype-dev  \
			curl-dev \
			doxygen \
			g++ \
			gcc \
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
			gmp-dev \
			jsoncpp-dev \
			openal-soft-dev \
			python3-dev \
            irrlicht-dev \
			zstd-dev \
			zlib-dev  \
			libxxf86vm-dev \
			jpeg-dev \
			sqlite-dev; \
		echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories; \
		apk add --update --no-cache \
			libspatialindex-dev; \
        git clone -b ${minetestVersion} --single-branch --depth 1 https://github.com/minetest/minetest.git; \
        cd /minetest; \
        git clone -b ${minetestVersion} --single-branch --depth 1 https://github.com/minetest/minetest_game.git games/minetest_game; \
		cmake . \
            -DBUILD_CLIENT=0 \
            -DBUILD_SERVER=1 \
            -DRUN_IN_PLACE=1 \
			-DCURSES_LIBRARY="/usr/lib/libcurses.so" \
			-DSQLITE3_LIBRARY="/usr/lib/libsqlite3.so" \
			-DENABLE_SYSTEM_GMP=1 \
            -DENABLE_SYSTEM_JSONCPP=0 \
            -DENABLE_FREETYPE=0 \
            -DENABLE_GETTEXT=0 \
            -DENABLE_LEVELDB=0 \
            -DENABLE_POSTGRESQL=0 \
            -DENABLE_REDIS=1 \
			-DREDIS_LIBRARY="/usr/lib/libhiredis.so" \
            -DENABLE_CURL=1 \
			-DCURL_LIBRARY="/usr/lib/libcurl.so" \
            -DENABLE_LUAJIT=1 \
			-DLUA_LIBRARY="/usr/lib/libluajit-5.1.so" \
            -DENABLE_SPATIAL=1 \
			-DSPATIAL_LIBRARY="/usr/lib/libspatialindex.so.6"; \
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
			echo "http://dl-cdn.alpinelinux.org/alpine/v3.14/community" >> /etc/apk/repositories; \
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
				json-c \
				hiredis \
				zstd \
				shadow; \
			echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories; \
			apk add --update --no-cache \
				libspatialindex;

		RUN set -ex; \
			mkdir -p /minetest/worlds; \
			mkdir -p /minetest/log; \
			addgroup --gid 1000 -S minetest; \
			adduser --uid 1000 -D -S -h /minetest -s /sbin/nologin -G minetest minetest; \
			ln -sf /dev/stdout /minetest/log/default.log;

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