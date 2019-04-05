#!/bin/sh

: ${NATTRADION_ASSETS:=/home/johannes/nattradion-assets}

docker run -v "$NATTRADION_ASSETS":/audio -p 8000:8000 nattradion
