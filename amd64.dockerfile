# :: Header
	FROM alpine:3.14
	ENV minetestVersion=5.4.1

# :: Run
	USER root

	RUN set -ex; \
		echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories; \
		mkdir -p /tmp/minetest; \
		mkdir -p /tmp/spatialindex; \
		mkdir -p /minetest; \
		mkdir -p /minetest/etc; \
		mkdir -p /minetest/worlds; \
		mkdir -p /minetest/games; \
		mkdir -p /minetest/games/minetest_game; \
		apk add --virtual=.build --update --no-cache \
			bzip2-dev \
			cmake \
			curl-dev \
			doxygen \
			g++ \
			gcc \
			gettext-dev \
			git \
			gmp-dev \
			hiredis-dev \
			icu-dev \
			irrlicht-dev \
			libjpeg-turbo-dev \
			libogg-dev \
			libpng-dev \
			libressl-dev \
			libtool \
			libvorbis-dev \
			luajit-dev \
			make \
			mesa-dev \
			ncurses-dev \
			openal-soft-dev \
			python3-dev \
			leveldb-dev \
			sqlite-dev; \
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
			shadow; \
		addgroup --gid 1000 -S minetest; \
		adduser --uid 1000 -D -S -h /minetest -s /sbin/nologin -G minetest minetest; \
		git clone https://github.com/libspatialindex/libspatialindex /tmp/spatialindex; \
		cd /tmp/spatialindex; \
		cmake . -DCMAKE_INSTALL_PREFIX=/usr; \
		make; \
		make install; \
		curl -o /tmp/minetest-src.tar.gz -L \
			"https://github.com/minetest/minetest/archive/${minetestVersion}.tar.gz"; \
		tar xf /tmp/minetest-src.tar.gz -C /tmp/minetest --strip-components=1; \
		cp /tmp/minetest/minetest.conf.example /minetest/etc/default.conf; \
		cd /tmp/minetest; \
		cmake .  \
			-DBUILD_CLIENT=0 \
			-DCMAKE_INSTALL_PREFIX=/usr \
			-DCUSTOM_BINDIR=/usr/bin \
			-DCUSTOM_DOCDIR="/usr/share/doc/minetest" \
			-DCUSTOM_SHAREDIR="/usr/share/minetest" \
			-DENABLE_CURL=1 \
			-DENABLE_FREETYPE=0 \
			-DENABLE_GETTEXT=0 \
			-DENABLE_LEVELDB=0 \
			-DENABLE_LUAJIT=1 \
			-DENABLE_REDIS=0 \
			-DENABLE_SOUND=1 \
			-DENABLE_SYSTEM_GMP=1 \
			-DRUN_IN_PLACE=0 \
			-DBUILD_SERVER=1; \
		make -j 2; \
		make install; \
		cp -R /usr/share/minetest/games /minetest; \
		rm -R /usr/share/minetest/games; \
		ln -s /minetest/games /usr/share/minetest/games; \
		curl -o /tmp/minetest-game.tar.gz -L \
			"https://github.com/minetest/minetest_game/archive/${minetestVersion}.tar.gz"; \
			tar xf /tmp/minetest-game.tar.gz -C /minetest/games/minetest_game --strip-components=1; \
		apk del --purge .build; \
		rm -rf /tmp/*

	COPY ./source/minetest.conf /minetest/etc/default.conf

	# :: docker -u 1000:1000 (no root initiative)
		RUN chown -R minetest:minetest /minetest

# :: Volumes
	VOLUME ["/minetest/etc", "/minetest/games", "/minetest/worlds"]

# :: Start
	USER minetest
	CMD ["minetestserver", "--config", "/minetest/etc/default.conf"]