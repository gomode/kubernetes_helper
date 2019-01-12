#!/usr/bin/env bash
GOOS=linux go build
docker build -t maidong/healthz:v1.0.0 -f Dockerfile .
docker push maidong/healthz:v1.0.0
