#!/usr/bash

function checkStatus()
{
  status=$(neutron lbaas-loadbalancer-show $1 | grep provisioning_status | awk -F '|' '{print $3}')
  echo checking loadbalancer $1, the status is $status.
  while [ $status != "ACTIVE" ]
  do
    echo Status is not ACTIVE, Check status again.
    status=$(neutron lbaas-loadbalancer-show $1 | grep provisioning_status | awk -F '|' '{print $3}')
  done
}

lb_name=$1

if [ -z $lb_name ]
then
  echo please provider a unique loadbalancer name
  exit 1
fi

source /home/heat-admin/overcloudrc

plist=$(neutron lbaas-pool-list | grep pl | awk -F '|' '{print $2}')
IFS=' ' read -r -a parray <<< $plist

checkStatus $lb_name
for element in "${parray[@]}"
do
   echo deleting pool $element
   neutron lbaas-pool-delete $element
   checkStatus $lb_name
done

llist=$(neutron lbaas-listener-list | grep ls | awk -F '|' '{print $2}')
IFS=' ' read -r -a larray <<< $llist

for element in "${larray[@]}"
do
   echo deleting listener $element
   neutron lbaas-listener-delete $element
   checkStatus $lb_name
done

echo deleting loadbalancer $lb_name
neutron lbaas-loadbalancer-delete $lb_name
