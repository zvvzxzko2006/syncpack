#!/bin/bash

RELEASE_SERVER_USER=developer
RELEASE_SERVER_HOST=127.0.0.1
RELEASE_SERVER_SSH_PORT=10022
RELEASE_SERVER_TARGET_PLATFORM=aarch64-ubuntu16.04
RELEASE_SERVER_PACK_ROOT=/release
RELEASE_SERVER_DEPENDS_ROOT=/depends
RELEASE_PATH=${RELEASE_SERVER_USER}@${RELEASE_SERVER_HOST}:${RELEASE_SERVER_PACK_ROOT}/${RELEASE_SERVER_TARGET_PLATFORM}
DEPENDS_PATH=${RELEASE_SERVER_USER}@${RELEASE_SERVER_HOST}:${RELEASE_SERVER_DEPENDS_ROOT}/${RELEASE_SERVER_TARGET_PLATFORM}

