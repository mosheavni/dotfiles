#!/bin/bash

# loop directories
for dir in */; do
  stow -Rv $dir
done
