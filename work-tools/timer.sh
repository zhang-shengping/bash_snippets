#!/bin/bash
start=$(date "+%s")
#do something
sleep 2
now=$(date "+%s")
time=$((now-start))
echo "time used:$time seconds"
