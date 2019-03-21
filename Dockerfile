FROM ubuntu:18.04 as builder

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

ENV SC_VERSION 3.10.2
ENV SC_MAJORVERSION 3.10
ENV SC_PLUGIN_VERSION 3.10.0

RUN apt-get update \
  && apt-get -y upgrade \
  && apt-get install -yq --no-install-recommends \
    build-essential \
    bzip2 \
    ca-certificates \
    cmake \
    git \
    jackd \
    libasound2-dev \
    libavahi-client-dev \
    libcwiid-dev \
    libfftw3-dev \
    libicu-dev \
    libjack-dev \
    libjack0 \
    libreadline6-dev \
    libsndfile1-dev \
    libudev-dev \
    libxt-dev \
    pkg-config \
    unzip \
    wget \
  \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $HOME/src \
  && cd $HOME/src \
  && wget -q https://github.com/supercollider/supercollider/releases/download/Version-$SC_VERSION/SuperCollider-$SC_VERSION-Source-linux.tar.bz2 -O sc.tar.bz2 \
  && tar xvf sc.tar.bz2 \
  && cd SuperCollider-Source \
  && mkdir -p build \
  && cd build \
  && cmake -DCMAKE_BUILD_TYPE="Release" -DNATIVE=ON -DBUILD_TESTING=OFF -DSUPERNOVA=OFF -DSC_WII=OFF -DSC_QT=OFF -DSC_ED=OFF -DSC_EL=OFF -DSC_VIM=OFF .. \
  && make -j4 \
  && make install \
  && ldconfig
  #&& ls -R /usr/local/share/SuperCollider \
  #&& rm -f /usr/local/share/SuperCollider/SCClassLibrary/deprecated/$SC_MAJORVERSION/deprecated-$SC_MAJORVERSION.sc \
  
RUN cd $HOME/src \
  && wget -q https://github.com/supercollider/sc3-plugins/releases/download/Version-$SC_PLUGIN_VERSION/sc3-plugins-$SC_PLUGIN_VERSION-Source.tar.bz2 -O scplugins.tar.bz2 \
  && tar xvf scplugins.tar.bz2 \
  && cd sc3-plugins-$SC_PLUGIN_VERSION-Source \
  && mkdir -p build \
  && cd build \
  && cmake -DSC_PATH=$HOME/src/SuperCollider-Source -DNATIVE=ON -DHOA_UGENS=OFF -DSUPERNOVA=OFF -DAY=OFF .. \
  && cmake --build . --config Release --target install \
  && rm -rf $HOME/src

RUN wget -q https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-amd64.tgz -O forego.tgz && \
	tar xvf forego.tgz && \
	rm forego.tgz && \
	chmod +x forego

FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
	apt-get install -y software-properties-common && \
	add-apt-repository -y multiverse && \
	apt-get update && \
    apt-get install -y icecast2 darkice libasound2 libasound2-plugins alsa-utils alsa-oss jackd1 jack-tools xvfb curl && \
    apt-get clean

COPY --from=builder forego /usr/bin/forego
COPY --from=builder /usr/local /usr/local
COPY asoundrc /root/.asoundrc

COPY icecast.xml /etc/icecast2/icecast.xml
COPY darkice.cfg /etc/darkice.cfg

COPY startup.scd /root/.config/SuperCollider/startup.scd
COPY nattradion /nattradion

COPY Procfile Procfile

EXPOSE 8000
RUN mv /etc/security/limits.d/audio.conf.disabled /etc/security/limits.d/audio.conf && \
	usermod -a -G audio root

CMD ["forego", "start"]
