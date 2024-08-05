FROM ubuntu:24.04 as base

RUN curl -fsSL https://packagecloud.io/84codes/crystal/gpgkey | gpg --dearmor | tee /etc/apt/trusted.gpg.d/84codes_crystal.gpg > /dev/null
RUN echo "deb https://packagecloud.io/84codes/crystal/any any main" | tee /etc/apt/sources.list.d/84codes_crystal.list
RUN apt-get update
RUN apt-get install -y crystal
