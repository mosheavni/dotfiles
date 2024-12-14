#!/bin/bash

stow -Rv .
# loop directories
for dir in */; do
  stow -Rv $dir
done
