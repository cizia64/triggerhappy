FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y build-essential git autoconf automake libtool

# Clone triggerhappy repository
RUN git clone https://github.com/wertarbyte/triggerhappy.git /triggerhappy

WORKDIR /triggerhappy

# Build triggerhappy
RUN autoreconf -i && \
    ./configure && \
    make && \
    make install
