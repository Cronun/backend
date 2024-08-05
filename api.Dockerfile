FROM ubuntu:24.04 as base

RUN apt-get update
RUN apt-get install -y libsqlite3-dev libevent-dev curl gnupg tree

FROM base AS builder

RUN curl -fsSL https://packagecloud.io/84codes/crystal/gpgkey | gpg --dearmor | tee /etc/apt/trusted.gpg.d/84codes_crystal.gpg > /dev/null
RUN echo "deb https://packagecloud.io/84codes/crystal/any any main" | tee /etc/apt/sources.list.d/84codes_crystal.list
RUN apt-get update
RUN apt-get install -y crystal

WORKDIR /app
COPY ./shard.yml ./shard.lock /app/
RUN shards install --production
COPY . /app/
RUN shards build --release --production --stats --time api
# RUN shards build --static --stats --time api

FROM base as release
WORKDIR /app
COPY --from=builder /app/src/data/*.db /app
COPY --from=builder /app/bin /app
RUN ls -alh .
RUN tree .

ENTRYPOINT ["/app/api"]
