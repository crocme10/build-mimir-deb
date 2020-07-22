FROM debian:jessie

WORKDIR /srv

RUN apt-get update \
    && apt-get install -y curl git build-essential \
    && apt-get install -y pkg-config libssl-dev sqlite3 libsqlite3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH "$PATH:/root/.cargo/bin"
ENV SQLITE3_LIB_DIR="/usr/lib/x86_64-linux-gnu"

RUN git clone https://github.com/crocme10/mimirsbrunn.git
WORKDIR /srv/mimirsbrunn
RUN git tag -l
RUN git checkout -b work tags/v1.15.1-rc

RUN cargo build --release

WORKDIR /srv
RUN mkdir deb

RUN mkdir deb/DEBIAN
RUN printf 'Package: mimirsbrunn\n\
Version: 0.15.1\n\
Section: custom\n\
Priority: optional\n\
Architecture: all\n\
Essential: no\n\
Installed-Size: 1024\n\
Maintainer: Matthieu Paindavoine <matthieu.paindavoine@kisio.org>\n\
Description: Binaries for indexing data into Mimir\n\
'\
>> deb/DEBIAN/control

RUN mkdir -p deb/usr/bin/
RUN cp mimirsbrunn/target/release/bano2mimir deb/usr/bin/bano2mimir
RUN cp mimirsbrunn/target/release/osm2mimir deb/usr/bin/osm2mimir
RUN cp mimirsbrunn/target/release/cosmogony2mimir deb/usr/bin/cosmogony2mimir
RUN cp mimirsbrunn/target/release/ntfs2mimir deb/usr/bin/ntfs2mimir
RUN cp mimirsbrunn/target/release/poi2mimir deb/usr/bin/poi2mimir
RUN cp mimirsbrunn/target/release/openaddresses2mimir deb/usr/bin/openaddresses2mimir
RUN cp mimirsbrunn/target/release/stops2mimir deb/usr/bin/stops2mimir

RUN dpkg-deb --build deb
RUN mv deb.deb mimirsbrunn-0.15.1.deb
