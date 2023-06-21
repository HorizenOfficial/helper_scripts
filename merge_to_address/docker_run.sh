#!/bin/bash

command -v docker >/dev/null 2>&1 || { echo "Docker is required"; exit 1; }

docker run --rm -it --network=host zen_merge_to_address $@
