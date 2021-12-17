FROM prwhitehead/vips-builder:latest as vips-builder
FROM ruby:3.0.3-bullseye

# Build essentials
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
		software-properties-common \
		build-essential \
		vim \
		curl \
		less && \
	apt-get clean && \
	rm -rf /var/cache/apt/archives/* && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	truncate -s 0 /var/log/*log

# Node / Yarn
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
		echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
RUN apt-get update && \
		DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends yarn nodejs

# Vips for image processing
ENV VIPSHOME /usr/local/vips
ENV PATH $VIPSHOME/bin:$PATH
ENV LD_LIBRARY_PATH $VIPSHOME/lib:$LD_LIBRARY_PATH
ENV PKG_CONFIG_PATH $VIPSHOME/lib/pkgconfig:$PKG_CONFIG_PATH

COPY --from=vips-builder /var/AptImageProcessingTools /tmp/AptImageProcessingTools
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $(cat /tmp/AptImageProcessingTools | xargs)

COPY --from=vips-builder /usr/local/libvips-dev.tar.gz /usr/local/
RUN cd /usr/local/ && \
		tar -xvzf libvips-dev.tar.gz && \
		rm -f libvips-dev.tar.gz && \
		pkg-config vips --cflags

# Clean up
RUN apt-get clean && \
		rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
		truncate -s 0 /var/log/*log

WORKDIR /usr/src/app

ENV LANG=C.UTF-8 \
		BUNDLE_JOBS=4 \
		BUNDLE_RETRY=3

COPY Gemfile* package* yarn* ./
RUN yarn install --check-files

RUN gem update --system && \
	gem install bundler && \
	bundle install

COPY . .

