source /home/heat-admin/pzhang/overcloudrc 

neutron lbaas-pool-list | grep ccy | awk -F "|" '{printf $2}' | xargs neutron lbaas-pool-delete
neutron lbaas-listener-list | grep ccy | awk -F "|" '{printf $4}' | xargs neutron lbaas-listener-delete
neutron lbaas-loadbalancer-list | grep ccy | awk -F '|' '{printf $2}' | xargs neutron lbaas-loadbalancer-delete
