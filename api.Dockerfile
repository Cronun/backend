FROM crystallang/crystal AS builder

WORKDIR /app
RUN apt-get update && apt-get install -y libsqlite3-dev
COPY ./shard.yml ./shard.lock /app/
RUN shards install --production
COPY . /app/
# RUN shards build --release --production --stats --time api
RUN shards build --stats --time api

FROM ubuntu:24.04 

WORKDIR /
COPY --from=builder /app/src/data .
COPY --from=builder /app/bin/api .

ENTRYPOINT ["/api"]
