FROM ubuntu:24.04 as base

WORKDIR /app
COPY src/data/*.db /app
