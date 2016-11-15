#!/bin/bash

for x in $(seq 1 200)
do
  ./progress $x 200
  sleep 0.02
done
echo
