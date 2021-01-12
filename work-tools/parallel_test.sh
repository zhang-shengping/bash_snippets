#!/usr/bash

# OPENSTACK_SOURCE
# LOADBALANCER_SUBNET
# MEMBER_SUBNET
# MB_SUBNET_IP

source test.sh

function source_file() {
  local idx=$1
  local sourcefile=test-pf-$idx.rc
  local source_path=/home/heat-admin/pzhang/test_users/$sourcefile
  echo $source_path
}

function lb_subnet() {
  local idx=$1
  lb_subnet_name=lb-subnet-$idx
  echo $lb_subnet_name
}

function mb_subnet() {
  local idx=$1
  local mb_subnet_name=mb-subnet-$idx 
  echo $mb_subnet_name
}

function mb_ip() {
  local idx=$1
  # start from 100
  local mb_ip_start=250.251.$idx
  echo $mb_ip_start
}

function task() {
  local idx=$1 
  
  OPENSTACK_SOURCE=$(source_file $idx)
  source $OPENSTACK_SOURCE
  LOADBALANCER_SUBNET=$(lb_subnet $idx)
  MEMBER_SUBNET=$(mb_subnet $idx)
  MB_SUBNET_IP=$(mb_ip $idx)

  local random_time=$((0 + RANDOM % 10))
  sleep $random_time
  create_resources 1 1 1 4 ccy_$idx
}


# ---- main ----
test_users=$1

user_index=0

if [ -z $test_users ]; then
  echo "please provider number of user to create"
  exit 1
fi

start=$(date "+%s")
echo "start at $start"

while [ $user_index -lt $test_users ]
do
  task $user_index &
  ((user_index++))
done
wait
now=$(date "+%s")
echo "end at $now"
time=$((now-start))
echo "parallell total time used:$time seconds"
