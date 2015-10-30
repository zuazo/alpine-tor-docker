#!/bin/sh

docker build --rm --force-rm "${@}" -t zuazo/alpine-tor .
