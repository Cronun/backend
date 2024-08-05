FROM ubuntu:24.04 as base

RUN apt-get update
RUN apt-get install -y libsqlite3-dev libevent-dev curl gnupg tree

