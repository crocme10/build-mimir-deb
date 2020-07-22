## Introduction

This is a dockerfile to generate a debian package for mimirsbrunn's binaries.

The goal is to obtain a debian package that can be installed on compatible debian machines,
and will provide these binaries for indexing data. These binaries are typically used by Tyr.

## Usage

Retrieve the dockerfile and build it:
```
git clone https://github.com/crocme10/build-mimir-deb
cd build-mimir-deb
docker build -t foobar -f Dockerfile .
```

This results in a debian package in the `/srv` directory.

There is probably a better way to extract that file from the container.... But for now, I just run
that container, and copy the file to the host filesystem:

```
docker run -t foobar:latest
```

```
docker container cp nifty_goldstine:srv/mimirsbrunn-0.15.1.deb /tmp
```

## Documentation
Here is a quick explanation of the Dockerfile:

We start with debian jessie, because that is the version of debian which runs tyr.

```
FROM debian:jessie
```

We then move to a directory, and install dependencies. Some of these dependencies are for rust
itself, others are for mimirsbrunn.

```
WORKDIR /srv

RUN apt-get update \
    && apt-get install -y curl git build-essential \
    && apt-get install -y pkg-config libssl-dev sqlite3 libsqlite3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

We proceed with installing rust. The command was adapted from that found on the rust lang website
so that it be non interactive:

```
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH "$PATH:/root/.cargo/bin"
```

We also add an environment variable required by `rusqlite`:

```
ENV SQLITE3_LIB_DIR="/usr/lib/x86_64-linux-gnu"
```

Finally, we retrieve mimirsbrunn and build it. This is obviously something you have to adjust for
your needs.  Here I get mimirsbrunn from my personnal repo, and I retrieve a specific tag. (Note
that the tag is important for mimirsbrunn, as it is the tag (given by the command `git describe`)
that will be used for the version of the program.

```
RUN git clone https://github.com/crocme10/mimirsbrunn.git
WORKDIR /srv/mimirsbrunn
RUN git tag -l
RUN git checkout -b work tags/v1.15.1-rc
RUN cargo build --release
```

Now we go on to build a debian package... We create a directory `deb`, with a file
`deb/DEBIAN/control` containing a description of the package:

```
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
```

And we create a file hierarchy which describes where we want the files to be installed.

```
RUN mkdir -p deb/usr/bin/
RUN cp mimirsbrunn/target/release/bano2mimir deb/usr/bin/bano2mimir
RUN cp mimirsbrunn/target/release/osm2mimir deb/usr/bin/osm2mimir
RUN cp mimirsbrunn/target/release/cosmogony2mimir deb/usr/bin/cosmogony2mimir
RUN cp mimirsbrunn/target/release/ntfs2mimir deb/usr/bin/ntfs2mimir
RUN cp mimirsbrunn/target/release/poi2mimir deb/usr/bin/poi2mimir
RUN cp mimirsbrunn/target/release/openaddresses2mimir deb/usr/bin/openaddresses2mimir
RUN cp mimirsbrunn/target/release/stops2mimir deb/usr/bin/stops2mimir
```

That's it.... just build it. Since its in a folder deb, it will be called `deb.deb`, not very
useful, so we move it to a better name.

```
RUN dpkg-deb --build deb
RUN mv deb.deb mimirsbrunn-0.15.1.deb
```
