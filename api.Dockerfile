FROM crystallang/crystal:1.13-dev-alpine-build as builder

WORKDIR /app
COPY ./shard.yml ./shard.lock /app/
RUN shards install --production -v
COPY . /app/
RUN shards build --static --release --production --stats --time -v api

FROM alpine:latest
WORKDIR /
COPY --from=builder /app/src/data .
COPY --from=builder /app/bin/api .

ENTRYPOINT ["/api"]
