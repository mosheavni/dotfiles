#!/bin/bash
script_dir=$(realpath $(dirname $0))
docker run -it --rm -v ${script_dir}:/root --privileged hiri bash
