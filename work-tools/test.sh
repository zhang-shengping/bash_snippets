#!/usr/bash

# OPENSTACK_SOURCE
# LOADBALANCER_SUBNET
# MEMBER_SUBNET
# MB_SUBNET_IP

function checkStatus()
{
  status=$(neutron lbaas-loadbalancer-show $1 | grep provisioning_status | awk -F '|' '{print $3}')
  echo checking loadbalancer $1, the status is $status.
  while [ $status != "ACTIVE" ]
  do
    if [ $status == "ERROR" ]; then
      echo "loadbalancer $1 is ERROR"
      break
    fi
    local random_time=$((0 + RANDOM % 10))
    sleep $random_time
    echo "loadbalancer $1 Status is not ACTIVE, Check status again."
    status=$(neutron lbaas-loadbalancer-show $1 | grep provisioning_status | awk -F '|' '{print $3}')
  done
}

function create_resources()
{
local pef_lb_subnet=$LOADBALANCER_SUBNET

local pef_mb_subnet=$MEMBER_SUBNET

local mb_subnet_ip=$MB_SUBNET_IP

# how many loadbalancer to create ...
local lbs=$1

# how many listener to create ...
local lss=$2

# how many pool to create ...
local pls=$3

# how many member to create ...
local mbs=$4

local user_idx=$5

echo "resource name prefix is: $user_idx"
echo "source file: OPENSTACK_SOURCE: $OPENSTACK_SOURCE"
echo "loadbalancer subnet: $pef_lb_subnet"
echo "member subnet: $pef_mb_subnet"
echo "member subnet ip: $mb_subnet_ip"
echo "number of loadbalancers for each (source file) user: $lbs"
echo "number of listeners for each loadbalancer: $lss"
echo "number of pools for each listener: $pls"
echo "number of members for each pools: $mbs"

if [ -z $lbs ]
then
  echo how many loadbalancers do you want? please provider the number in commandline
  exit 1
fi

# pzhang for parallel test comment, because something neutron-server is busy and no response
# lb_subnet=$(neutron subnet-list | grep --color $pef_lb_subnet | awk -F '|' '{print $3}')
# mb_subnet=$(neutron subnet-list | grep --color $pef_mb_subnet | awk -F '|' '{print $3}')

# if [ -z $lb_subnet ]
# then
#   echo please create subnet pef_lb_subnet for performance test
#   exit 1
# fi

# if [ -z $mb_subnet ]
# then
#   echo please create subnet pef_mb_subnet for performance test
#   exit 1
# fi


# init loadbalancer counter 
local lbi=0

# set timer start
start=$(date "+%s")

while [ $lbi -lt $lbs ]
do
  lb_name=$user_idx-lb-$lbi
  lb_cli_start=$(date "+%s")

  neutron lbaas-loadbalancer-create --name $lb_name $pef_lb_subnet

  lb_cli_now=$(date "+%s")
  lb_cli_time=$((lb_cli_now-lb_cli_start))
  echo Loadbalancer $lb_name creation: Neutron-server reponses in $lb_cli_time seconds

  # check loadbalacner status
  checkStatus $lb_name

  lb_active_now=$(date "+%s")
  lb_active_time=$((lb_active_now-lb_cli_now))
  echo Loadbalancer $lb_name activated in $lb_active_time seconds

  # init listener counter
  local lsi=0
 
  while [ $lsi -lt $lss ]
  do
    ((ls_port_num=$lsi+1))
    ls_name=$user_idx-ls-$lbi-$lsi
    ls_cli_start=$(date "+%s")

    neutron lbaas-listener-create --name $ls_name --loadbalancer $lb_name --protocol TCP --protocol-port $ls_port_num

    ls_cli_now=$(date "+%s")
    ls_cli_time=$((ls_cli_now-ls_cli_start))
    echo Listener $ls_name creation: Neutron-server reponses in $ls_cli_time seconds
    
    checkStatus $lb_name

    ls_active_now=$(date "+%s")
    ls_active_time=$((ls_active_now-ls_cli_now))
    echo Listener $ls_name activated in $ls_active_time seconds

    # init pool counter
    local pli=0

    while [ $pli -lt $pls ]
    do 
      pl_name=$user_idx-pl-$lbi-$lsi-$pli
      pl_cli_start=$(date "+%s")

      neutron lbaas-pool-create --name $pl_name --lb-algorithm ROUND_ROBIN --listener $ls_name --protocol TCP

      pl_cli_now=$(date "+%s")
      pl_cli_time=$((pl_cli_now-pl_cli_start))
      echo Pool $pl_name creation: Neutron-server reponses in $pl_cli_time seconds

      checkStatus $lb_name

      pl_active_now=$(date "+%s")
      pl_active_time=$((pl_active_now-pl_cli_now))
      echo Pool $pl_name activated in $pl_active_time seconds

      # init member counter 
      local mbi=0

      while [ $mbi -lt $mbs ]
      do
        ((member_port_num=$mbi+1))
        mb_name=$user_idx-mb-$lbi-$lsi-$pli-$mbi
        mb_cli_start=$(date "+%s")

        # pzhang this change for concurrency test
        local cip=$((10+$mbi))
        neutron lbaas-member-create --name $mb_name --subnet $pef_mb_subnet --address $mb_subnet_ip.$cip --protocol-port $member_port_num $pl_name

        # pzhang this is origin
        # neutron lbaas-member-create --name $mb_name --subnet $pef_mb_subnet --address $mb_subnet_ip.$mbi --protocol-port $member_port_num $pl_name

        mb_cli_now=$(date "+%s")
        mb_cli_time=$((mb_cli_now-mb_cli_start))
        echo Member $mb_name creation: Neutron-server reponses in $mb_cli_time seconds

        checkStatus $lb_name

        mb_active_now=$(date "+%s")
        mb_active_time=$((mb_active_now-mb_cli_now))
        echo Member $mb_name activated in $mb_active_time seconds

        ((mbi++))
      done

      ((pli++))
    done
    
    ((lsi++))
  done

  ((lbi++))
done

# set timer end
now=$(date "+%s")

# calculate time
time=$((now-start))
echo "$user_idx time used:$time seconds"
}

function create_source() {
  local pn=$1
  local un=$2
  local pd=$3
  local sourcefile=test-$pn.rc
  local origin_admin=/home/heat-admin/pzhang/overcloudrc
  local new_admin=/home/heat-admin/pzhang/test_users/$sourcefile

  cp $origin_admin $new_admin
  sed -i "s/OS_USERNAME=.*/OS_USERNAME=$un/g" $new_admin
  sed -i "s/OS_PROJECT_NAME=.*/OS_PROJECT_NAME=$pn/g" $new_admin
  sed -i "s/OS_PASSWORD=.*/OS_PASSWORD=$pd/g" $new_admin
  
  echo $new_admin
}

function create_admin_user() {
  local index=$1
  local project_name=pf-$index
  local user_name=pf-$index
  local password=Passw0rd

  openstack project create --domain default $project_name
  openstack user create --domain default --password $password $user_name
  openstack role add --project $project_name --user $user_name admin

  OPENSTACK_SOURCE=$(create_source $project_name $user_name $password) 
}

function set_unlimited_quota() {
  neutron quota-update --loadbalancer -1
  neutron quota-update --floatingip -1
  neutron quota-update --healthmonitor -1
  neutron quota-update --l7policy -1
  neutron quota-update --listener -1
  neutron quota-update --loadbalancer -1
  neutron quota-update --member -1
  neutron quota-update --network -1
  neutron quota-update --pool -1
  neutron quota-update --port -1
  neutron quota-update --router -1
  neutron quota-update --security_group -1
  neutron quota-update --subnet -1
}

function create_net() {
  local index=$1

  local lb_net_name=lb-net-$index
  local lb_subnet_name=lb-subnet-$index

  local mb_net_name=mb-net-$index
  local mb_subnet_name=mb-subnet-$index

  local lb_ip=250.250.$index.0/24
  local mb_ip=250.251.$index.0/24
  
  # create subnet for LOADBALANCER
  neutron net-create $lb_net_name
  neutron subnet-create $lb_net_name $lb_ip --name $lb_subnet_name

  # create subnet for MEMBER
  neutron net-create $mb_net_name
  neutron subnet-create $mb_net_name $mb_ip --name $mb_subnet_name

  LOADBALANCER_SUBNET=$lb_subnet_name
  MEMBER_SUBNET=$mb_subnet_name

  # LB_SUBNET_IP=250.250.$index
  MB_SUBNET_IP=250.251.$index
}

# --- main ----

# echo start
# source /home/heat-admin/pzhang/overcloudrc

# test_users=$1
# # loadbalancer_num=$2
# # listener_num=$3
# # pool_num=$4
# # member_num=$5

# user_index=0

# if [ -z $test_users ]; then
#   echo "please provider number of user to create"
#   exit 1 
# fi

# while [ $user_index -lt $test_users ]
# do
#   source /home/heat-admin/pzhang/overcloudrc

#   create_admin_user $user_index  
#   source $OPENSTACK_SOURCE

#   # set global variables of LOADBALANCER subnet and MEMBER subnet implicitly
#   create_net $user_index

#   set_unlimited_quota
#   create_resources 1 4 1 4 $user_index
#   ((user_index++))
# done
