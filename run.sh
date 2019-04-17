#!/bin/sh

: ${NATTRADION_ASSETS:=/home/johannes/nattradion-assets}

sudo docker rm nattradion
#-dit
sudo docker run --name nattradion -v "$NATTRADION_ASSETS":/audio --privileged=true -p 443:443 nattradion
