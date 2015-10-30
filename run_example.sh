#!/bin/sh

docker run \
  -ti \
  --rm \
  zuazo/alpine-tor "${@}"
