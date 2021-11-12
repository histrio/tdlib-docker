FROM ubuntu:focal as lib-builder

ENV DEBIAN_FRONTEND=noninteractive

# Get build requirements
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install make git zlib1g-dev libssl-dev gperf php-cli clang-10 libc++-dev libc++abi-dev wget g++

#Get and build cmake
ARG CMAKE_VERSION=3.21.4
RUN wget --no-check-certificate https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz && \
    tar xf cmake-$CMAKE_VERSION.tar.gz && \
    cd cmake-$CMAKE_VERSION && ./bootstrap && make && make install

#Get and make tdlib
ARG TDLIB_VERSION=1.7.0
RUN git clone https://github.com/tdlib/td.git && \
    cd td && git checkout v$TDLIB_VERSION && rm -rf build && mkdir build && \
    cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . --target prepare_cross_compiling 

RUN cd td && php SplitSource.php && \
    cd build && \
    cmake --build . --target tdjson && \
    cmake --build . --target tdjson_static && \
    cd .. && php SplitSource.php --undo

FROM ubuntu:focal
RUN apt-get update && apt-get install -y git openssl python3 libc++-dev && mkdir /app
COPY --from=lib-builder td/build/libtdjson.so* /app/
